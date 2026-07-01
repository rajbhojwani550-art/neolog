import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/ga_calculator.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../services/local_storage.dart';
import '../../../babies/models/baby_model.dart';
import '../../../babies/providers/babies_provider.dart';

class MbdScreen extends ConsumerStatefulWidget {
  final String babyId;
  const MbdScreen({super.key, required this.babyId});

  @override
  ConsumerState<MbdScreen> createState() => _MbdScreenState();
}

class _MbdScreenState extends ConsumerState<MbdScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _onTpnSinceBirth = false;
  bool _hasCholestasis = false;
  bool _onBoneMeds = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final storage = ref.read(localStorageProvider);
    final configs = storage.getScreeningsForBaby(widget.babyId, 'mbd_config');
    if (configs.isNotEmpty) {
      final c = configs.first;
      _onTpnSinceBirth = c['onTpnSinceBirth'] as bool? ?? false;
      _hasCholestasis = c['hasCholestasis'] as bool? ?? false;
      _onBoneMeds = c['onBoneMeds'] as bool? ?? false;
    }
    _results = storage.getScreeningsForBaby(widget.babyId, 'mbd')
      ..sort((a, b) => DateTime.parse(b['screenDate'] as String)
          .compareTo(DateTime.parse(a['screenDate'] as String)));
    setState(() {});
  }

  void _saveConfig() {
    final storage = ref.read(localStorageProvider);
    storage.saveScreening('mbd_config', {
      'id': 'mbd_config_${widget.babyId}',
      'babyId': widget.babyId,
      'onTpnSinceBirth': _onTpnSinceBirth,
      'hasCholestasis': _hasCholestasis,
      'onBoneMeds': _onBoneMeds,
    });
  }

  bool _isEligible(BabyModel baby) {
    if (baby.gaWeeks < 30) return true;
    if (baby.gaWeeks <= 34 &&
        (_onTpnSinceBirth || _hasCholestasis || _onBoneMeds)) return true;
    return false;
  }

  DateTime _firstScreenDate(BabyModel baby) {
    // AIIMS: 2 weeks if on TPN since birth, else 4 weeks
    if (_onTpnSinceBirth) return baby.dateOfBirth.add(const Duration(days: 14));
    return baby.dateOfBirth.add(const Duration(days: 28));
  }

  bool _canStopMonitoring(BabyModel baby) {
    if (_results.isEmpty) return false;
    final latest = _results.first;
    final alp = latest['alp'] as int?;
    final po4 = (latest['phosphate'] as num?)?.toDouble();
    // AIIMS: stop if ALP < 500-600 AND P > 4 mg/dL
    if (alp != null && po4 != null && alp < 600 && po4 > 4.0) return true;
    // Also stop at 40w PMA
    return baby.correctedGAWeeks >= 40.0;
  }

  DateTime? _nextFollowUpDate(BabyModel baby) {
    if (!_isEligible(baby)) return null;
    if (_canStopMonitoring(baby)) return null;
    if (_results.isEmpty) return _firstScreenDate(baby);
    final latestDate = DateTime.parse(_results.first['screenDate'] as String);
    return latestDate.add(const Duration(days: 14));
  }

  // Phosphate in mg/dL. AIIMS: Abnormal = ALP > 900 AND PO4 < 5.6 mg/dL
  String _interpret(double? ca, double? po4, int? alp) {
    final alpHigh = alp != null && alp > 900;
    final po4Low = po4 != null && po4 < 5.6;

    if (alpHigh && po4Low) return 'MBD (AIIMS) — maximize Ca, P, Vit D';

    final issues = <String>[];
    if (alp != null) {
      if (alp > 900) issues.add('ALP >900 — check PO4');
      else if (alp > 500) issues.add('Suspected MBD (ALP >500)');
    }
    if (po4 != null) {
      if (po4 < 4.0) issues.add('Severe hypophosphataemia');
      else if (po4 < 5.6) issues.add('Low PO4 (MBD risk)');
    }
    if (ca != null) {
      if (ca < 1.8) issues.add('Hypocalcaemia');
      else if (ca > 2.8) issues.add('Hypercalcaemia');
    }
    return issues.isEmpty ? 'Normal' : issues.join(', ');
  }

  Color _alpColor(int alp) {
    if (alp > 900) return AppColors.alert;
    if (alp > 500) return AppColors.warning;
    return AppColors.success;
  }

  // PO4 in mg/dL
  Color _po4Color(double po4) {
    if (po4 < 4.0) return AppColors.alert;
    if (po4 < 5.6) return AppColors.warning;
    return AppColors.success;
  }

  Color _caColor(double ca) {
    if (ca < 1.8 || ca > 2.8) return AppColors.alert;
    if (ca < 2.1 || ca > 2.7) return AppColors.warning;
    return AppColors.success;
  }

  Color _interpretColor(String interp) {
    if (interp.contains('MBD (AIIMS)') ||
        interp.contains('Hypocalcaemia') ||
        interp.contains('Severe') ||
        interp.contains('severely')) return AppColors.alert;
    if (interp.contains('Suspected') ||
        interp.contains('Low PO4') ||
        interp.contains('>900') ||
        interp.contains('Hypercalcaemia')) return AppColors.warning;
    return AppColors.success;
  }

  void _showAddResult(BabyModel baby) {
    final caCtrl = TextEditingController();
    final po4Ctrl = TextEditingController();
    final alpCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String treatment = 'none';
    DateTime screenDate = DateTime.now();

    const treatments = [
      'none',
      'Ca supplementation',
      'PO4 supplementation',
      'Ca + PO4 supplementation',
      'Vitamin D (400 IU/day)',
      'Vitamin D3 2000 IU/day × 3 months',
      'Ca + PO4 + Vitamin D',
      'Calcitriol',
      'HMF fortification of breast milk',
      'Increase TPN minerals',
      'Stop bone-active medication',
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
                  'AIIMS Protocol — Serum Ca, PO4 (mg/dL), ALP',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
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
                TextFormField(
                  controller: caCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Calcium (mmol/L)',
                    hintText: 'e.g. 2.3',
                    prefixIcon: const Icon(Icons.science),
                    suffixText: 'mmol/L',
                    helperText: 'Normal: 2.1–2.7  |  < 1.8 = Hypocalcaemia',
                    helperStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: po4Ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Phosphate (mg/dL)',
                    hintText: 'e.g. 5.8',
                    prefixIcon: const Icon(Icons.science),
                    suffixText: 'mg/dL',
                    helperText:
                        'Normal: 4.8–8.2  |  <5.6 = Low  |  >4.0 = OK to stop',
                    helperStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: alpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ALP (IU/L)',
                    hintText: 'e.g. 350',
                    prefixIcon: const Icon(Icons.science),
                    suffixText: 'IU/L',
                    helperText:
                        '>500 = suspect  |  >900 + PO4 <5.6 = AIIMS abnormal',
                    helperStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: treatment,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Treatment / Plan',
                    prefixIcon: Icon(Icons.medication),
                  ),
                  items: treatments
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) ss(() => treatment = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Plan',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final ca = double.tryParse(caCtrl.text);
                    final po4 = double.tryParse(po4Ctrl.text);
                    final alp = int.tryParse(alpCtrl.text);
                    if (ca == null && po4 == null && alp == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter at least one value'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }
                    final storage = ref.read(localStorageProvider);
                    storage.saveScreening('mbd', {
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'screenDate': screenDate.toIso8601String(),
                      'dayOfLife': GACalculator.dayOfLife(
                          baby.dateOfBirth, screenDate),
                      'calcium': ca,
                      'phosphate': po4,
                      'alp': alp,
                      'treatment': treatment,
                      'notes': notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      'interpretation': _interpret(ca, po4, alp),
                    });
                    _loadData();
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

  @override
  Widget build(BuildContext context) {
    final baby = ref.watch(babyProvider(widget.babyId));
    if (baby == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('MBD Screening')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    final eligible = _isEligible(baby);
    final firstScreen = _firstScreenDate(baby);
    final nextFollowUp = _nextFollowUpDate(baby);
    final stopMonitoring = _canStopMonitoring(baby);
    final firstScreenDol = firstScreen.difference(baby.dateOfBirth).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MBD Screening',
                style: TextStyle(fontSize: 16)),
            Text(
              'GA ${baby.gaWeeks}+${baby.gaDays}w  •  DOL ${baby.dayOfLife}  •  CGA ${baby.correctedGA}w',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Eligibility + Risk Factors
          _EligibilityCard(
            gaWeeks: baby.gaWeeks,
            eligible: eligible,
            onTpnSinceBirth: _onTpnSinceBirth,
            hasCholestasis: _hasCholestasis,
            onBoneMeds: _onBoneMeds,
            onChanged: (tpn, chol, bone) {
              setState(() {
                _onTpnSinceBirth = tpn;
                _hasCholestasis = chol;
                _onBoneMeds = bone;
              });
              _saveConfig();
            },
          ),

          // Scheduling
          if (eligible)
            _ScheduleCard(
              firstScreenDate: firstScreen,
              firstScreenDol: firstScreenDol,
              nextFollowUpDate: nextFollowUp,
              stopMonitoring: stopMonitoring,
              hasResults: _results.isNotEmpty,
            ),

          // AIIMS reference
          _AiimsReferenceCard(),

          // Trend
          if (_results.length >= 2) ...[
            const SectionHeader(
                title: 'Trend', icon: Icons.trending_up),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TrendCard(results: _results),
            ),
          ],

          // History
          const SectionHeader(
              title: 'Results History', icon: Icons.history),

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
                      eligible
                          ? 'No MBD screens recorded'
                          : 'MBD screening not indicated',
                      style:
                          TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      eligible
                          ? 'First screen due: ${AppDateUtils.formatDate(firstScreen)} (DOL $firstScreenDol)'
                          : 'Criteria: GA <30w, or GA 30–34w with TPN/cholestasis/bone meds',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400),
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
                      ? _po4Color(
                          (r['phosphate'] as num).toDouble())
                      : Colors.grey,
                  caColor: r['calcium'] != null
                      ? _caColor(
                          (r['calcium'] as num).toDouble())
                      : Colors.grey,
                  interpretColor: _interpretColor(
                      r['interpretation'] as String? ?? 'Normal'),
                )),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: eligible
          ? FloatingActionButton.extended(
              onPressed: () => _showAddResult(baby),
              icon: const Icon(Icons.add),
              label: const Text('Add Result'),
            )
          : null,
    );
  }
}

// ─── Eligibility Card ────────────────────────────────────────────────────────

class _EligibilityCard extends StatelessWidget {
  final int gaWeeks;
  final bool eligible;
  final bool onTpnSinceBirth;
  final bool hasCholestasis;
  final bool onBoneMeds;
  final void Function(bool tpn, bool chol, bool bone) onChanged;

  const _EligibilityCard({
    required this.gaWeeks,
    required this.eligible,
    required this.onTpnSinceBirth,
    required this.hasCholestasis,
    required this.onBoneMeds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        eligible ? AppColors.primary : Colors.grey;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(
                  eligible
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gaWeeks < 30
                        ? 'Indicated — GA < 30 weeks (AIIMS)'
                        : gaWeeks <= 34
                            ? eligible
                                ? 'Indicated — GA 30–34w with risk factor(s)'
                                : 'GA 30–34w — confirm risk factors below'
                            : 'Not indicated — GA ≥ 35 weeks',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gaWeeks >= 30 && gaWeeks <= 34) ...[
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(6, 6, 6, 2),
                    child: Text(
                      'Risk factors (≥1 required for GA 30–34w):',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600),
                    ),
                  ),
                ],
                if (gaWeeks < 35) ...[
                  _RiskTile(
                    label: gaWeeks < 30
                        ? 'On TPN since birth  →  first screen at 2 weeks (not 4)'
                        : 'On TPN > 2 weeks',
                    value: onTpnSinceBirth,
                    onChanged: (v) =>
                        onChanged(v, hasCholestasis, onBoneMeds),
                  ),
                ],
                if (gaWeeks >= 30 && gaWeeks <= 34) ...[
                  _RiskTile(
                    label: 'Cholestasis',
                    value: hasCholestasis,
                    onChanged: (v) =>
                        onChanged(onTpnSinceBirth, v, onBoneMeds),
                  ),
                  _RiskTile(
                    label:
                        'Bone-active meds > 2w (steroids / loop diuretics / methylxanthine)',
                    value: onBoneMeds,
                    onChanged: (v) =>
                        onChanged(onTpnSinceBirth, hasCholestasis, v),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _RiskTile(
      {required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      title: Text(label,
          style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}

// ─── Schedule Card ────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final DateTime firstScreenDate;
  final int firstScreenDol;
  final DateTime? nextFollowUpDate;
  final bool stopMonitoring;
  final bool hasResults;

  const _ScheduleCard({
    required this.firstScreenDate,
    required this.firstScreenDol,
    required this.nextFollowUpDate,
    required this.stopMonitoring,
    required this.hasResults,
  });

  @override
  Widget build(BuildContext context) {
    if (stopMonitoring) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle,
                color: AppColors.success, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Monitoring complete — ALP <600 IU/L and PO4 >4 mg/dL',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final target = nextFollowUpDate;
    final isOverdue = target != null && target.isBefore(now);
    final daysUntil =
        target != null ? target.difference(now).inDays : 0;
    final statusColor = isOverdue
        ? AppColors.alert
        : (daysUntil <= 3 ? AppColors.warning : AppColors.primary);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasResults
                      ? 'Next screen due'
                      : 'First screen due',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
                if (target != null) ...[
                  Text(
                    AppDateUtils.formatDate(target),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                  Text(
                    isOverdue
                        ? 'Overdue by ${-daysUntil} days'
                        : daysUntil == 0
                            ? 'Due today'
                            : 'In $daysUntil day${daysUntil == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 11, color: statusColor),
                  ),
                ],
              ],
            ),
          ),
          if (!hasResults)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DOL\n$firstScreenDol',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── AIIMS Reference Card ─────────────────────────────────────────────────────

class _AiimsReferenceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline,
                  size: 15, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'AIIMS Reference Ranges',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RefRow('Calcium', '2.1–2.7 mmol/L',
              '<1.8 = Hypocalcaemia'),
          _RefRow('Phosphate', '4.8–8.2 mg/dL',
              '<5.6 = Low (MBD risk)  •  >4.0 = OK to stop'),
          _RefRow('ALP', '<400 IU/L normal',
              '>500 = suspect  •  >900 + PO4<5.6 = Abnormal'),
          const SizedBox(height: 4),
          Text(
            '* In cholestasis: do not rely on ALP — use PO4 only\n'
            '* PO4 supplements: 20 mg/kg/day → max 50 mg/kg/day',
            style: TextStyle(
                fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _RefRow extends StatelessWidget {
  final String label;
  final String normal;
  final String flag;
  const _RefRow(this.label, this.normal, this.flag);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
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

// ─── Result Card ─────────────────────────────────────────────────────────────

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
    final date = DateTime.parse(result['screenDate'] as String);
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
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatDate(date),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
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
                    color: interpretColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: interpretColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    interpretation,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: interpretColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (ca != null)
                  Expanded(
                    child: _ValueTile(
                      label: 'Ca',
                      value:
                          (ca as num).toStringAsFixed(2),
                      unit: 'mmol/L',
                      color: caColor,
                    ),
                  ),
                if (po4 != null)
                  Expanded(
                    child: _ValueTile(
                      label: 'PO4',
                      value:
                          (po4 as num).toStringAsFixed(1),
                      unit: 'mg/dL',
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
                      size: 14,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      treatment,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
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
                    fontSize: 12,
                    color: AppColors.textSecondary),
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
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(unit,
              style: TextStyle(
                  fontSize: 9, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

// ─── Trend Card ───────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  const _TrendCard({required this.results});

  @override
  Widget build(BuildContext context) {
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
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest vs previous',
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
                noChangeThreshold: 0.1,
              )),
              Expanded(
                  child: _TrendItem(
                label: 'PO4',
                prev:
                    (previous['phosphate'] as num?)?.toDouble(),
                curr:
                    (latest['phosphate'] as num?)?.toDouble(),
                unit: 'mg/dL',
                goodDirection: 'up',
                noChangeThreshold: 0.5,
              )),
              Expanded(
                  child: _TrendItem(
                label: 'ALP',
                prev: (previous['alp'] as num?)?.toDouble(),
                curr: (latest['alp'] as num?)?.toDouble(),
                unit: 'IU/L',
                goodDirection: 'down',
                noChangeThreshold: 50,
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
  final String goodDirection;
  final double noChangeThreshold;

  const _TrendItem({
    required this.label,
    required this.prev,
    required this.curr,
    required this.unit,
    required this.goodDirection,
    required this.noChangeThreshold,
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
    final improving =
        goodDirection == 'down' ? diff < 0 : diff > 0;
    final noChange = diff.abs() < noChangeThreshold;
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
              label == 'ALP'
                  ? curr!.toStringAsFixed(0)
                  : curr!.toStringAsFixed(1),
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
