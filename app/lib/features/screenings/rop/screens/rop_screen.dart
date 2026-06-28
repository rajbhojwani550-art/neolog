import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/ga_calculator.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../services/local_storage.dart';
import '../../../babies/providers/babies_provider.dart';

class RopScreen extends ConsumerStatefulWidget {
  final String babyId;
  const RopScreen({super.key, required this.babyId});

  @override
  ConsumerState<RopScreen> createState() => _RopScreenState();
}

class _RopScreenState extends ConsumerState<RopScreen> {
  List<Map<String, dynamic>> _screenings = [];

  @override
  void initState() {
    super.initState();
    _loadScreenings();
  }

  void _loadScreenings() {
    final storage = ref.read(localStorageProvider);
    _screenings = storage.getScreeningsForBaby(widget.babyId, 'rop')
      ..sort((a, b) => DateTime.parse(b['screeningDate'] as String)
          .compareTo(DateTime.parse(a['screeningDate'] as String)));
    setState(() {});
  }

  void _showAddExam() {
    String eyeExamined = 'both';
    String rZone = '2', lZone = '2';
    String rStage = '0', lStage = '0';
    bool plusDisease = false, apRop = false;
    String treatment = 'none';
    final examinerC = TextEditingController();
    final notesC = TextEditingController();
    DateTime examDate = DateTime.now();
    DateTime? nextDate;

    final stages = ['0', '1', '2', '3', '4a', '4b', '5'];
    final zones = ['1', '2', '3'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add ROP Exam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: examDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (p != null) ss(() => examDate = p);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Exam Date'),
                    child: Text('${examDate.day}/${examDate.month}/${examDate.year}'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Right Eye', style: TextStyle(fontWeight: FontWeight.w600)),
                Row(children: [
                  Expanded(child: DropdownButtonFormField(value: rZone, decoration: const InputDecoration(labelText: 'Zone'), items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(), onChanged: (v) { if (v != null) ss(() => rZone = v); })),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(value: rStage, decoration: const InputDecoration(labelText: 'Stage'), items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { if (v != null) ss(() => rStage = v); })),
                ]),
                const SizedBox(height: 12),
                const Text('Left Eye', style: TextStyle(fontWeight: FontWeight.w600)),
                Row(children: [
                  Expanded(child: DropdownButtonFormField(value: lZone, decoration: const InputDecoration(labelText: 'Zone'), items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(), onChanged: (v) { if (v != null) ss(() => lZone = v); })),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(value: lStage, decoration: const InputDecoration(labelText: 'Stage'), items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { if (v != null) ss(() => lStage = v); })),
                ]),
                SwitchListTile(title: const Text('Plus Disease'), value: plusDisease, onChanged: (v) => ss(() => plusDisease = v), contentPadding: EdgeInsets.zero),
                SwitchListTile(title: const Text('AP-ROP'), value: apRop, onChanged: (v) => ss(() => apRop = v), contentPadding: EdgeInsets.zero),
                DropdownButtonFormField(value: treatment, decoration: const InputDecoration(labelText: 'Treatment'), items: ['none', 'laser', 'bevacizumab', 'surgery'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) { if (v != null) ss(() => treatment = v); }),
                const SizedBox(height: 12),
                TextFormField(controller: examinerC, decoration: const InputDecoration(labelText: 'Ophthalmologist')),
                const SizedBox(height: 12),
                TextFormField(controller: notesC, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 14)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                    if (p != null) ss(() => nextDate = p);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Next Exam Date'),
                    child: Text(nextDate != null ? '${nextDate!.day}/${nextDate!.month}/${nextDate!.year}' : 'Tap to select'),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final storage = ref.read(localStorageProvider);
                    storage.saveScreening('rop', {
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'screeningDate': examDate.toIso8601String(),
                      'eyeExamined': eyeExamined,
                      'rightEye_zone': rZone, 'rightEye_stage': rStage,
                      'leftEye_zone': lZone, 'leftEye_stage': lStage,
                      'plusDisease': plusDisease, 'aggressivePosteriorROP': apRop,
                      'treatment': treatment,
                      'examinedBy': examinerC.text,
                      'nextExamDate': nextDate?.toIso8601String(),
                      'notes': notesC.text,
                    });
                    _loadScreenings();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Exam'),
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

    return Scaffold(
      appBar: AppBar(title: const Text('ROP Screening')),
      body: ListView(
        children: [
          if (baby != null && GACalculator.needsRopScreening(baby.gaWeeks, baby.birthWeightGrams))
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Text('Screening Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'First exam due: ${AppDateUtils.formatDate(GACalculator.ropFirstScreeningDate(baby.dateOfBirth, baby.gaWeeks, baby.gaDays))}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          const SectionHeader(title: 'Exam History'),
          if (_screenings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('No ROP exams recorded', style: TextStyle(color: Colors.grey.shade500))),
            )
          else
            ..._screenings.map((s) => _RopExamCard(screening: s)),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExam,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RopExamCard extends StatelessWidget {
  final Map<String, dynamic> screening;
  const _RopExamCard({required this.screening});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(screening['screeningDate'] as String);
    final rStage = screening['rightEye_stage'] ?? '0';
    final lStage = screening['leftEye_stage'] ?? '0';
    final plusDisease = screening['plusDisease'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppDateUtils.formatDate(date), style: const TextStyle(fontWeight: FontWeight.w600)),
                if (plusDisease)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.alert.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Plus Disease', style: TextStyle(color: AppColors.alert, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _EyeChip('RE', 'Z${screening['rightEye_zone']} S$rStage', _stageColor(rStage)),
                const SizedBox(width: 12),
                _EyeChip('LE', 'Z${screening['leftEye_zone']} S$lStage', _stageColor(lStage)),
              ],
            ),
            if (screening['treatment'] != null && screening['treatment'] != 'none') ...[
              const SizedBox(height: 8),
              Text('Treatment: ${screening['treatment']}', style: const TextStyle(fontSize: 13)),
            ],
            if (screening['examinedBy'] != null && (screening['examinedBy'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('By: ${screening['examinedBy']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case '0': return AppColors.success;
      case '1': return AppColors.gradeOne;
      case '2': return AppColors.gradeTwo;
      case '3': return AppColors.gradeThree;
      default: return AppColors.gradeFour;
    }
  }
}

class _EyeChip extends StatelessWidget {
  final String eye;
  final String label;
  final Color color;
  const _EyeChip(this.eye, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$eye: $label', style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
    );
  }
}
