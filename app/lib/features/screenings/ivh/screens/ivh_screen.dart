import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/ga_calculator.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../services/local_storage.dart';
import '../../../babies/providers/babies_provider.dart';

class IvhScreen extends ConsumerStatefulWidget {
  final String babyId;
  const IvhScreen({super.key, required this.babyId});

  @override
  ConsumerState<IvhScreen> createState() => _IvhScreenState();
}

class _IvhScreenState extends ConsumerState<IvhScreen> {
  List<Map<String, dynamic>> _screenings = [];

  @override
  void initState() {
    super.initState();
    _loadScreenings();
  }

  void _loadScreenings() {
    final storage = ref.read(localStorageProvider);
    _screenings = storage.getScreeningsForBaby(widget.babyId, 'ivh')
      ..sort((a, b) => DateTime.parse(b['screeningDate'] as String)
          .compareTo(DateTime.parse(a['screeningDate'] as String)));
    setState(() {});
  }

  void _showAddScan() {
    String rightGrade = 'none', leftGrade = 'none';
    bool pvl = false, cysticPvl = false;
    final radiologistC = TextEditingController();
    final findingsC = TextEditingController();
    DateTime scanDate = DateTime.now();
    DateTime? nextDate;

    final grades = ['none', '1', '2', '3', '4'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add Head USS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: scanDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (p != null) ss(() => scanDate = p);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Scan Date'),
                    child: Text('${scanDate.day}/${scanDate.month}/${scanDate.year}'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: DropdownButtonFormField(value: rightGrade, decoration: const InputDecoration(labelText: 'Right Side Grade'), items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g == 'none' ? 'None' : 'Grade $g'))).toList(), onChanged: (v) { if (v != null) ss(() => rightGrade = v); })),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(value: leftGrade, decoration: const InputDecoration(labelText: 'Left Side Grade'), items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g == 'none' ? 'None' : 'Grade $g'))).toList(), onChanged: (v) { if (v != null) ss(() => leftGrade = v); })),
                ]),
                SwitchListTile(title: const Text('PVL'), value: pvl, onChanged: (v) => ss(() => pvl = v), contentPadding: EdgeInsets.zero),
                SwitchListTile(title: const Text('Cystic PVL'), value: cysticPvl, onChanged: (v) => ss(() => cysticPvl = v), contentPadding: EdgeInsets.zero),
                TextFormField(controller: radiologistC, decoration: const InputDecoration(labelText: 'Radiologist')),
                const SizedBox(height: 12),
                TextFormField(controller: findingsC, maxLines: 2, decoration: const InputDecoration(labelText: 'Findings')),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                    if (p != null) ss(() => nextDate = p);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Next Scan Date'),
                    child: Text(nextDate != null ? '${nextDate!.day}/${nextDate!.month}/${nextDate!.year}' : 'Tap to select'),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final baby = ref.read(babyProvider(widget.babyId));
                    final storage = ref.read(localStorageProvider);
                    storage.saveScreening('ivh', {
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'screeningDate': scanDate.toIso8601String(),
                      'dayOfLife': baby != null ? GACalculator.dayOfLife(baby.dateOfBirth, scanDate) : 0,
                      'rightSide_grade': rightGrade,
                      'leftSide_grade': leftGrade,
                      'periventricularLeukomalacia': pvl,
                      'cysticPVL': cysticPvl,
                      'radiologistName': radiologistC.text,
                      'findings': findingsC.text,
                      'nextScanDate': nextDate?.toIso8601String(),
                    });
                    _loadScreenings();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Scan'),
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
      appBar: AppBar(title: const Text('IVH Screening')),
      body: ListView(
        children: [
          if (baby != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Screening Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('72 hours: ${AppDateUtils.formatDate(GACalculator.ivhFirstScanDate(baby.dateOfBirth))}', style: const TextStyle(fontSize: 13)),
                  Text('Day 7: ${AppDateUtils.formatDate(GACalculator.ivhSecondScanDate(baby.dateOfBirth))}', style: const TextStyle(fontSize: 13)),
                  Text('Day 28: ${AppDateUtils.formatDate(GACalculator.ivhThirdScanDate(baby.dateOfBirth))}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          const SectionHeader(title: 'Scan History'),
          if (_screenings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('No head USS recorded', style: TextStyle(color: Colors.grey.shade500))),
            )
          else
            ..._screenings.map((s) => _IvhScanCard(screening: s)),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddScan, child: const Icon(Icons.add)),
    );
  }
}

class _IvhScanCard extends StatelessWidget {
  final Map<String, dynamic> screening;
  const _IvhScanCard({required this.screening});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(screening['screeningDate'] as String);
    final rGrade = screening['rightSide_grade'] ?? 'none';
    final lGrade = screening['leftSide_grade'] ?? 'none';
    final pvl = screening['periventricularLeukomalacia'] == true;

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
                if (screening['dayOfLife'] != null)
                  Text('DOL ${screening['dayOfLife']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              _GradeChip('Right', rGrade),
              const SizedBox(width: 12),
              _GradeChip('Left', lGrade),
              if (pvl) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.alert.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('PVL', style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ]),
            if (screening['findings'] != null && (screening['findings'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(screening['findings'] as String, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String side;
  final String grade;
  const _GradeChip(this.side, this.grade);

  Color get _color {
    switch (grade) {
      case 'none': return AppColors.gradeNone;
      case '1': return AppColors.gradeOne;
      case '2': return AppColors.gradeTwo;
      case '3': return AppColors.gradeThree;
      case '4': return AppColors.gradeFour;
      default: return AppColors.gradeNone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text('$side: ${grade == "none" ? "Normal" : "Grade $grade"}',
          style: TextStyle(fontWeight: FontWeight.w600, color: _color, fontSize: 13)),
    );
  }
}
