import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/ga_calculator.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../services/local_storage.dart';
import '../../../babies/providers/babies_provider.dart';

class MbdScreen extends ConsumerStatefulWidget {
  final String babyId;
  const MbdScreen({super.key, required this.babyId});

  @override
  ConsumerState<MbdScreen> createState() => _MbdScreenState();
}

class _MbdScreenState extends ConsumerState<MbdScreen> {
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  void _loadResults() {
    final storage = ref.read(localStorageProvider);
    _results = storage.getScreeningsForBaby(widget.babyId, 'mbd')
      ..sort((a, b) => DateTime.parse(b['screenDate'] as String)
          .compareTo(DateTime.parse(a['screenDate'] as String)));
    setState(() {});
  }

  void _showAddResult() {
    final caController = TextEditingController();
    final po4Controller = TextEditingController();
    final alpController = TextEditingController();
    final notesController = TextEditingController();
    String treatment = 'none';
    DateTime screenDate = DateTime.now();

    final treatments = [
      'none',
      'Ca supplementation',
      'PO4 supplementation',
      'Ca + PO4 supplementation',
      'Vitamin D',
      'Calcitriol',
      'Ca + PO4 + Vitamin D',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add MBD Screen Result',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Metabolic Bone Disease Screening',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                // Date
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: screenDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (p != null) ss(() => screenDate = p);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Sample',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                        '${screenDate.day}/${screenDate.month}/${screenDate.year}'),
                  ),
                ),
                const SizedBox(height: 16),

                // Calcium
                TextFormField(
                  controller: caController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Calcium (mmol/L)',
                    hintText: 'Normal: 2.1–2.7',
                    prefixIcon: const Icon(Icons.science),
                    suffixText: 'mmol/L',
                    helperText: 'Preterm reference: 2.1–2.7 mmol/L',
                    helperStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),

                // Phosphate
                TextFormField(
                  controller: po4Controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Phosphate (mmol/L)',
                    hintText: 'Normal: 1.5–2.5',
                    prefixIcon: const Icon(Icons.science),
                    suffixText: 'mmol/L',
                    helperText: 'MBD risk if < 1.5 mmol/L',
                    helperStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),

                // ALP
                TextFormField(
                  controller: alpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ALP (IU/L)',
                    hintText: 'Normal: < 400',
                    prefixIcon: const Icon(Icons.science),
                    suffixText: 'IU/L',
                    helperText:
                        '> 500: suspect MBD   > 900: severe MBD',
                    helperStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),

                // Treatment
                DropdownButtonFormField<String>(
                  value: treatment,
                  decoration: const InputDecoration(
                    labelText: 'Treatment / Plan',
                    prefixIcon: Icon(Icons.medication),
                  ),
                  items: treatments
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) ss(() => treatment = v);
                  },
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Interpretation',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    final ca = double.tryParse(caController.text);
                    final po4 = double.tryParse(po4Controller.text);
                    final alp = int.tryParse(alpController.text);

                    if (ca == null && po4 == null && alp == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please enter at least one value'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }

                    final baby = ref.read(babyProvider(widget.babyId));
                    final storage = ref.read(localStorageProvider);

                    storage.saveScreening('mbd', {
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'screenDate': screenDate.toIso8601String(),
                      'dayOfLife': baby != null
                          ? GACalculator.dayOfLife(
                              baby.dateOfBirth, screenDate)
                          : null,
                      'calcium': ca,
                      'phosphate': po4,
                      'alp': alp,
                      'treatment': treatment,
                      'notes': notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      'interpretation':
                          _interpret(ca, po4, alp),
                    });
                    _loadResults();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Save Result'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _interpret(double? ca, double? po4, int? alp) {
    final issues = <String>[];

    if (alp != null) {
      if (alp > 900) issues.add('Severe MBD (ALP > 900)');
      else if (alp > 500) issues.add('Suspected MBD (ALP > 500)');
    }
    if (po4 != null) {
      if (po4 < 1.5) issues.add('Low phosphate');
      else if (po4 < 1.8) issues.add('Borderline low phosphate');
    }
    if (ca != null) {
      if (ca < 1.8) issues.add('Hypocalcaemia');
      else if (ca > 2.8) issues.add('Hypercalcaemia');
    }

    if (issues.isEmpty) return 'Normal';
    return issues.join(', ');
  }

  Color _alpColor(int alp) {
    if (alp > 900) return AppColors.alert;
    if (alp > 500) return AppColors.warning;
    return AppColors.success;
  }

  Color _po4Color(double po4) {
    if (po4 < 1.5) return AppColors.alert;
    if (po4 < 1.8) return AppColors.warning;
    return AppColors.success;
  }

  Color _caColor(double ca) {
    if (ca < 1.8 || ca > 2.8) return AppColors.alert;
    if (ca < 2.1 || ca > 2.7) return AppColors.warning;
    return AppColors.success;
  }

  Color _interpretationColor(String interp) {
    if (interp.contains('Severe') || interp.contains('Hypocalcaemia') ||
        interp.contains('Hypercalcaemia') || interp.contains('Low phosphate'))
      return AppColors.alert;
    if (interp.contains('Suspected') || interp.contains('Borderline'))
      return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final baby = ref.watch(babyProvider(widget.babyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('MBD Screening'),
      ),
      body: ListView(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Metabolic Bone Disease (MBD)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ReferenceRow('Calcium', '2.1–2.7 mmol/L',
                    '< 1.8 = Hypocalcaemia'),
                _ReferenceRow('Phosphate', '1.5–2.5 mmol/L',
                    '< 1.5 = Low PO4 (MBD risk)'),
                _ReferenceRow('ALP', '< 400 IU/L',
                    '> 500 = Suspect MBD  |  > 900 = Severe'),
              ],
            ),
          ),

          // Trend cards if >1 result
          if (_results.length >= 2) ...[
            const SectionHeader(
                title: 'Trend', icon: Icons.trending_up),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TrendCard(results: _results),
            ),
          ],

          // History
          const SectionHeader(title: 'Results History',
              icon: Icons.history),

          if (_results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.science_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No MBD screens recorded',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Screen at 4–6 weeks of life for preterms\n< 28 weeks or < 1000g',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._results.map((r) => _MbdResultCard(
                  result: r,
                  alpColor: r['alp'] != null
                      ? _alpColor(r['alp'] as int)
                      : Colors.grey,
                  po4Color: r['phosphate'] != null
                      ? _po4Color((r['phosphate'] as num).toDouble())
                      : Colors.grey,
                  caColor: r['calcium'] != null
                      ? _caColor(
                          (r['calcium'] as num).toDouble())
                      : Colors.grey,
                  interpretColor: _interpretationColor(
                      r['interpretation'] as String? ?? 'Normal'),
                )),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddResult,
        icon: const Icon(Icons.add),
        label: const Text('Add Result'),
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  final String label;
  final String normal;
  final String flag;
  const _ReferenceRow(this.label, this.normal, this.flag);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              '$normal   •   $flag',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MbdResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final Color alpColor;
  final Color po4Color;
  final Color caColor;
  final Color interpretColor;

  const _MbdResultCard({
    required this.result,
    required this.alpColor,
    required this.po4Color,
    required this.caColor,
    required this.interpretColor,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.parse(result['screenDate'] as String);
    final ca = result['calcium'];
    final po4 = result['phosphate'];
    final alp = result['alp'];
    final interpretation =
        result['interpretation'] as String? ?? 'Normal';
    final treatment = result['treatment'] as String? ?? 'none';
    final dol = result['dayOfLife'];

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatDate(date),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (dol != null)
                      Text(
                        'DOL $dol',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: interpretColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: interpretColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    interpretation,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: interpretColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Values row
            Row(
              children: [
                if (ca != null)
                  Expanded(
                    child: _ValueTile(
                      label: 'Calcium',
                      value:
                          '${(ca as num).toStringAsFixed(2)}',
                      unit: 'mmol/L',
                      color: caColor,
                    ),
                  ),
                if (po4 != null)
                  Expanded(
                    child: _ValueTile(
                      label: 'Phosphate',
                      value:
                          '${(po4 as num).toStringAsFixed(2)}',
                      unit: 'mmol/L',
                      color: po4Color,
                    ),
                  ),
                if (alp != null)
                  Expanded(
                    child: _ValueTile(
                      label: 'ALP',
                      value: '$alp',
                      unit: 'IU/L',
                      color: alpColor,
                    ),
                  ),
              ],
            ),

            if (treatment != 'none') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.medication_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    treatment,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (result['notes'] != null &&
                (result['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                result['notes'] as String,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _ValueTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  const _TrendCard({required this.results});

  @override
  Widget build(BuildContext context) {
    // Latest vs previous
    final latest = results.first;
    final previous = results[1];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 2 results',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _TrendItem(
                label: 'Ca',
                prev: (previous['calcium'] as num?)?.toDouble(),
                curr: (latest['calcium'] as num?)?.toDouble(),
                unit: 'mmol/L',
                goodDirection: 'up',
              )),
              Expanded(
                  child: _TrendItem(
                label: 'PO4',
                prev:
                    (previous['phosphate'] as num?)?.toDouble(),
                curr: (latest['phosphate'] as num?)?.toDouble(),
                unit: 'mmol/L',
                goodDirection: 'up',
              )),
              Expanded(
                  child: _TrendItem(
                label: 'ALP',
                prev: (previous['alp'] as num?)?.toDouble(),
                curr: (latest['alp'] as num?)?.toDouble(),
                unit: 'IU/L',
                goodDirection: 'down',
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendItem extends StatelessWidget {
  final String label;
  final double? prev;
  final double? curr;
  final String unit;
  final String goodDirection; // 'up' or 'down'

  const _TrendItem({
    required this.label,
    required this.prev,
    required this.curr,
    required this.unit,
    required this.goodDirection,
  });

  @override
  Widget build(BuildContext context) {
    if (prev == null || curr == null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      );
    }

    final diff = curr! - prev!;
    final improving = goodDirection == 'down' ? diff < 0 : diff > 0;
    final noChange = diff.abs() < 0.5;
    final color = noChange
        ? AppColors.textSecondary
        : improving
            ? AppColors.success
            : AppColors.warning;
    final icon = noChange
        ? Icons.remove
        : diff > 0
            ? Icons.arrow_upward
            : Icons.arrow_downward;

    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 2),
            Text(
              curr!.toStringAsFixed(
                  label == 'ALP' ? 0 : 1),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ],
        ),
        Text(unit,
            style: const TextStyle(
                fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}
