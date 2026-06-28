import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/local_storage.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  final String babyId;
  const MedicationsScreen({super.key, required this.babyId});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  List<Map<String, dynamic>> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  void _loadMedications() {
    final storage = ref.read(localStorageProvider);
    _medications = storage.getMedicationsForBaby(widget.babyId)
      ..sort((a, b) {
        final aStop = a['stopDate'] as String?;
        final bStop = b['stopDate'] as String?;
        if (aStop == null && bStop != null) return -1;
        if (aStop != null && bStop == null) return 1;
        return DateTime.parse(b['startDate'] as String)
            .compareTo(DateTime.parse(a['startDate'] as String));
      });
    setState(() {});
  }

  void _showAddMedication() {
    final drugC = TextEditingController();
    final indicationC = TextEditingController();
    final doseC = TextEditingController();
    final notesC = TextEditingController();
    String unit = 'mg', frequency = 'BD', route = 'IV';
    DateTime startDate = DateTime.now();

    final units = ['mg', 'mg/kg', 'mcg', 'mcg/kg', 'ml', 'units'];
    final frequencies = ['OD', 'BD', 'TDS', 'QID', 'Q6H', 'Q8H', 'Q12H', 'Q24H', 'STAT', 'PRN'];
    final routes = ['IV', 'IM', 'PO', 'SC', 'IT', 'PR', 'INH', 'topical'];

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
                const Text('Add Medication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(controller: drugC, decoration: const InputDecoration(labelText: 'Drug Name *')),
                const SizedBox(height: 12),
                TextFormField(controller: indicationC, decoration: const InputDecoration(labelText: 'Indication')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: doseC, decoration: const InputDecoration(labelText: 'Dose'))),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(value: unit, decoration: const InputDecoration(labelText: 'Unit'), items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) { if (v != null) ss(() => unit = v); })),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: DropdownButtonFormField(value: frequency, decoration: const InputDecoration(labelText: 'Frequency'), items: frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) { if (v != null) ss(() => frequency = v); })),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(value: route, decoration: const InputDecoration(labelText: 'Route'), items: routes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) { if (v != null) ss(() => route = v); })),
                ]),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (p != null) ss(() => startDate = p);
                  },
                  child: InputDecorator(decoration: const InputDecoration(labelText: 'Start Date'), child: Text('${startDate.day}/${startDate.month}/${startDate.year}')),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: notesC, decoration: const InputDecoration(labelText: 'Notes')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (drugC.text.trim().isEmpty) return;
                    final storage = ref.read(localStorageProvider);
                    storage.saveMedication({
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'drugName': drugC.text.trim(),
                      'indication': indicationC.text.trim(),
                      'startDate': startDate.toIso8601String(),
                      'stopDate': null,
                      'dose': doseC.text,
                      'unit': unit,
                      'frequency': frequency,
                      'route': route,
                      'notes': notesC.text,
                    });
                    _loadMedications();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Medication'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _stopMedication(Map<String, dynamic> med) async {
    final storage = ref.read(localStorageProvider);
    await storage.saveMedication({
      ...med,
      'stopDate': DateTime.now().toIso8601String(),
    });
    _loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    final active = _medications.where((m) => m['stopDate'] == null).toList();
    final stopped = _medications.where((m) => m['stopDate'] != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: ListView(
        children: [
          const SectionHeader(title: 'Current Medications'),
          if (active.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text('No active medications', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...active.map((m) => _MedCard(med: m, onStop: () => _stopMedication(m))),
          if (stopped.isNotEmpty) ...[
            const SectionHeader(title: 'Past Medications'),
            ...stopped.map((m) => _MedCard(med: m, stopped: true)),
          ],
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddMedication, child: const Icon(Icons.add)),
    );
  }
}

class _MedCard extends StatelessWidget {
  final Map<String, dynamic> med;
  final bool stopped;
  final VoidCallback? onStop;

  const _MedCard({required this.med, this.stopped = false, this.onStop});

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.parse(med['startDate'] as String);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stopped ? Colors.grey.shade200 : AppColors.secondary.withOpacity(0.15),
          child: Icon(Icons.medication, color: stopped ? Colors.grey : AppColors.secondary, size: 20),
        ),
        title: Text(
          med['drugName'] as String,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: stopped ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${med['dose']} ${med['unit']} ${med['frequency']} ${med['route']}\nStarted: ${AppDateUtils.formatDate(startDate)}',
        ),
        isThreeLine: true,
        trailing: stopped
            ? null
            : TextButton(
                onPressed: onStop,
                child: const Text('Stop', style: TextStyle(color: AppColors.alert)),
              ),
      ),
    );
  }
}
