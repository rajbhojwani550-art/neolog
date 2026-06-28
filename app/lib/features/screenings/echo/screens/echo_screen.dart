import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../services/local_storage.dart';
import '../../../babies/providers/babies_provider.dart';

class EchoScreen extends ConsumerStatefulWidget {
  final String babyId;
  const EchoScreen({super.key, required this.babyId});

  @override
  ConsumerState<EchoScreen> createState() => _EchoScreenState();
}

class _EchoScreenState extends ConsumerState<EchoScreen> {
  List<Map<String, dynamic>> _screenings = [];

  @override
  void initState() {
    super.initState();
    _loadScreenings();
  }

  void _loadScreenings() {
    final storage = ref.read(localStorageProvider);
    _screenings = storage.getScreeningsForBaby(widget.babyId, 'echo')
      ..sort((a, b) => DateTime.parse(b['reportDate'] as String)
          .compareTo(DateTime.parse(a['reportDate'] as String)));
    setState(() {});
  }

  void _showAddEcho() {
    String pda = 'closed', pdaFlow = 'left-to-right', pdaTreatment = 'none';
    String pht = 'none';
    bool pdaOnTreatment = false, asd = false, vsd = false;
    final lvefC = TextEditingController();
    final asdSizeC = TextEditingController();
    final vsdSizeC = TextEditingController();
    final cardioC = TextEditingController();
    final notesC = TextEditingController();
    DateTime reportDate = DateTime.now();
    DateTime? nextDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add Echo Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: reportDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (p != null) ss(() => reportDate = p);
                  },
                  child: InputDecorator(decoration: const InputDecoration(labelText: 'Report Date'), child: Text('${reportDate.day}/${reportDate.month}/${reportDate.year}')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(value: pda, decoration: const InputDecoration(labelText: 'PDA'), items: ['closed', 'small', 'moderate', 'large'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) ss(() => pda = v); }),
                if (pda != 'closed') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField(value: pdaFlow, decoration: const InputDecoration(labelText: 'PDA Flow'), items: ['left-to-right', 'bidirectional', 'right-to-left'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) ss(() => pdaFlow = v); }),
                  SwitchListTile(title: const Text('On Treatment'), value: pdaOnTreatment, onChanged: (v) => ss(() => pdaOnTreatment = v), contentPadding: EdgeInsets.zero),
                  if (pdaOnTreatment) DropdownButtonFormField(value: pdaTreatment, decoration: const InputDecoration(labelText: 'PDA Treatment'), items: ['none', 'indomethacin', 'ibuprofen', 'paracetamol', 'ligation'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) ss(() => pdaTreatment = v); }),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField(value: pht, decoration: const InputDecoration(labelText: 'Pulmonary Hypertension'), items: ['none', 'mild', 'moderate', 'severe'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) ss(() => pht = v); }),
                const SizedBox(height: 12),
                TextFormField(controller: lvefC, decoration: const InputDecoration(labelText: 'LVEF (%)', hintText: 'e.g. 65')),
                const SizedBox(height: 12),
                SwitchListTile(title: const Text('ASD'), value: asd, onChanged: (v) => ss(() => asd = v), contentPadding: EdgeInsets.zero),
                if (asd) TextFormField(controller: asdSizeC, decoration: const InputDecoration(labelText: 'ASD Size (mm)')),
                SwitchListTile(title: const Text('VSD'), value: vsd, onChanged: (v) => ss(() => vsd = v), contentPadding: EdgeInsets.zero),
                if (vsd) TextFormField(controller: vsdSizeC, decoration: const InputDecoration(labelText: 'VSD Size (mm)')),
                const SizedBox(height: 12),
                TextFormField(controller: cardioC, decoration: const InputDecoration(labelText: 'Cardiologist')),
                const SizedBox(height: 12),
                TextFormField(controller: notesC, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final storage = ref.read(localStorageProvider);
                    storage.saveScreening('echo', {
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'reportDate': reportDate.toIso8601String(),
                      'pda': pda, 'pdaFlow': pda != 'closed' ? pdaFlow : null,
                      'pdaOnTreatment': pdaOnTreatment, 'pdaTreatment': pdaTreatment,
                      'pulmonaryHypertension': pht,
                      'lvef': lvefC.text.isNotEmpty ? double.tryParse(lvefC.text) : null,
                      'asd': asd, 'asdSize': asdSizeC.text.isNotEmpty ? asdSizeC.text : null,
                      'vsd': vsd, 'vsdSize': vsdSizeC.text.isNotEmpty ? vsdSizeC.text : null,
                      'cardiologistName': cardioC.text,
                      'notes': notesC.text,
                      'nextEchoDate': nextDate?.toIso8601String(),
                    });
                    _loadScreenings();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Echo'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('2D Echo')),
      body: ListView(
        children: [
          const SectionHeader(title: 'Echo History'),
          if (_screenings.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No echo reports', style: TextStyle(color: Colors.grey.shade500))))
          else
            ..._screenings.map((s) => _EchoCard(screening: s)),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddEcho, child: const Icon(Icons.add)),
    );
  }
}

class _EchoCard extends StatelessWidget {
  final Map<String, dynamic> screening;
  const _EchoCard({required this.screening});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(screening['reportDate'] as String);
    final pda = screening['pda'] ?? 'closed';
    final pht = screening['pulmonaryHypertension'] ?? 'none';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppDateUtils.formatDate(date), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              _StatusBadge('PDA', pda, _pdaColor(pda)),
              const SizedBox(width: 12),
              if (pht != 'none') _StatusBadge('PHT', pht, _phtColor(pht)),
            ]),
            if (screening['pdaOnTreatment'] == true) ...[
              const SizedBox(height: 4),
              Text('Treatment: ${screening['pdaTreatment']}', style: const TextStyle(fontSize: 12)),
            ],
            if (screening['lvef'] != null) Text('LVEF: ${screening['lvef']}%', style: const TextStyle(fontSize: 13)),
            if (screening['asd'] == true) Text('ASD: ${screening['asdSize'] ?? "present"}', style: const TextStyle(fontSize: 13)),
            if (screening['vsd'] == true) Text('VSD: ${screening['vsdSize'] ?? "present"}', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Color _pdaColor(String pda) {
    switch (pda) {
      case 'closed': return AppColors.success;
      case 'small': return AppColors.warning;
      case 'moderate': return AppColors.pdaOrange;
      case 'large': return AppColors.alert;
      default: return AppColors.textSecondary;
    }
  }

  Color _phtColor(String pht) {
    switch (pht) {
      case 'mild': return AppColors.warning;
      case 'moderate': return AppColors.pdaOrange;
      case 'severe': return AppColors.alert;
      default: return AppColors.textSecondary;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatusBadge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text('$label: $value', style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
    );
  }
}
