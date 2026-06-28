import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/local_storage.dart';

class InvestigationsScreen extends ConsumerStatefulWidget {
  final String babyId;
  const InvestigationsScreen({super.key, required this.babyId});

  @override
  ConsumerState<InvestigationsScreen> createState() => _InvestigationsScreenState();
}

class _InvestigationsScreenState extends ConsumerState<InvestigationsScreen> {
  List<Map<String, dynamic>> _investigations = [];

  @override
  void initState() {
    super.initState();
    _loadInvestigations();
  }

  void _loadInvestigations() {
    final storage = ref.read(localStorageProvider);
    _investigations = storage.getInvestigationsForBaby(widget.babyId)
      ..sort((a, b) => DateTime.parse(b['collectedDate'] as String)
          .compareTo(DateTime.parse(a['collectedDate'] as String)));
    setState(() {});
  }

  void _showAddInvestigation() {
    String category = 'blood', interpretation = 'normal';
    final testNameC = TextEditingController();
    final resultC = TextEditingController();
    final notesC = TextEditingController();
    DateTime collectedDate = DateTime.now();

    final categories = ['blood', 'urine', 'csf', 'culture', 'imaging', 'other'];
    final interpretations = ['normal', 'abnormal', 'critical'];

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
                const Text('Add Investigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: collectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (p != null) ss(() => collectedDate = p);
                  },
                  child: InputDecorator(decoration: const InputDecoration(labelText: 'Collected Date'), child: Text('${collectedDate.day}/${collectedDate.month}/${collectedDate.year}')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(value: category, decoration: const InputDecoration(labelText: 'Category'), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) ss(() => category = v); }),
                const SizedBox(height: 12),
                TextFormField(controller: testNameC, decoration: const InputDecoration(labelText: 'Test Name *', hintText: 'e.g. CBC, CRP, Blood Culture')),
                const SizedBox(height: 12),
                TextFormField(controller: resultC, maxLines: 3, decoration: const InputDecoration(labelText: 'Result', alignLabelWithHint: true)),
                const SizedBox(height: 12),
                DropdownButtonFormField(value: interpretation, decoration: const InputDecoration(labelText: 'Interpretation'), items: interpretations.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: (v) { if (v != null) ss(() => interpretation = v); }),
                const SizedBox(height: 12),
                TextFormField(controller: notesC, decoration: const InputDecoration(labelText: 'Notes')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (testNameC.text.trim().isEmpty) return;
                    final storage = ref.read(localStorageProvider);
                    storage.saveInvestigation({
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'collectedDate': collectedDate.toIso8601String(),
                      'reportDate': collectedDate.toIso8601String(),
                      'category': category,
                      'testName': testNameC.text.trim(),
                      'result': resultC.text.trim(),
                      'interpretation': interpretation,
                      'notes': notesC.text.trim(),
                    });
                    _loadInvestigations();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Investigation'),
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
      appBar: AppBar(title: const Text('Investigations')),
      body: ListView(
        children: [
          const SectionHeader(title: 'Results'),
          if (_investigations.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No investigations recorded', style: TextStyle(color: Colors.grey.shade500))))
          else
            ..._investigations.map((inv) {
              final date = DateTime.parse(inv['collectedDate'] as String);
              final interpretation = inv['interpretation'] as String? ?? 'normal';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _interpColor(interpretation).withOpacity(0.15),
                    child: Icon(_categoryIcon(inv['category'] as String? ?? 'other'), color: _interpColor(interpretation), size: 20),
                  ),
                  title: Text(inv['testName'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppDateUtils.formatDate(date)),
                      if (inv['result'] != null && (inv['result'] as String).isNotEmpty)
                        Text(inv['result'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _interpColor(interpretation).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(interpretation, style: TextStyle(color: _interpColor(interpretation), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddInvestigation, child: const Icon(Icons.add)),
    );
  }

  Color _interpColor(String interp) {
    switch (interp) {
      case 'normal': return AppColors.success;
      case 'abnormal': return AppColors.warning;
      case 'critical': return AppColors.alert;
      default: return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'blood': return Icons.bloodtype;
      case 'urine': return Icons.science;
      case 'csf': return Icons.water_drop;
      case 'culture': return Icons.biotech;
      case 'imaging': return Icons.image;
      default: return Icons.assignment;
    }
  }
}
