import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../services/local_storage.dart';

class NbsScreen extends ConsumerStatefulWidget {
  final String babyId;
  const NbsScreen({super.key, required this.babyId});

  @override
  ConsumerState<NbsScreen> createState() => _NbsScreenState();
}

class _NbsScreenState extends ConsumerState<NbsScreen> {
  List<Map<String, dynamic>> _screenings = [];

  @override
  void initState() {
    super.initState();
    _loadScreenings();
  }

  void _loadScreenings() {
    final storage = ref.read(localStorageProvider);
    _screenings = storage.getScreeningsForBaby(widget.babyId, 'nbs')
      ..sort((a, b) => DateTime.parse(b['collectionDate'] as String)
          .compareTo(DateTime.parse(a['collectionDate'] as String)));
    setState(() {});
  }

  void _showAddNbs() {
    String status = 'sent';
    final tshC = TextEditingController();
    final ohpC = TextEditingController();
    final pkuC = TextEditingController();
    final notesC = TextEditingController();
    DateTime collectionDate = DateTime.now();

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
                const Text('Add NBS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: collectionDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (p != null) ss(() => collectionDate = p);
                  },
                  child: InputDecorator(decoration: const InputDecoration(labelText: 'Collection Date'), child: Text('${collectionDate.day}/${collectionDate.month}/${collectionDate.year}')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(value: status, decoration: const InputDecoration(labelText: 'Status'), items: ['sent', 'resulted', 'abnormal'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { if (v != null) ss(() => status = v); }),
                if (status == 'resulted' || status == 'abnormal') ...[
                  const SizedBox(height: 12),
                  TextFormField(controller: tshC, decoration: const InputDecoration(labelText: 'TSH')),
                  const SizedBox(height: 12),
                  TextFormField(controller: ohpC, decoration: const InputDecoration(labelText: '17-OHP')),
                  const SizedBox(height: 12),
                  TextFormField(controller: pkuC, decoration: const InputDecoration(labelText: 'PKU / Phenylalanine')),
                ],
                const SizedBox(height: 12),
                TextFormField(controller: notesC, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final storage = ref.read(localStorageProvider);
                    storage.saveScreening('nbs', {
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'collectionDate': collectionDate.toIso8601String(),
                      'status': status,
                      'results': {
                        if (tshC.text.isNotEmpty) 'TSH': tshC.text,
                        if (ohpC.text.isNotEmpty) '17-OHP': ohpC.text,
                        if (pkuC.text.isNotEmpty) 'PKU': pkuC.text,
                      },
                      'notes': notesC.text,
                    });
                    _loadScreenings();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save NBS'),
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
      appBar: AppBar(title: const Text('Newborn Blood Spot')),
      body: ListView(
        children: [
          const SectionHeader(title: 'NBS History'),
          if (_screenings.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No NBS recorded', style: TextStyle(color: Colors.grey.shade500))))
          else
            ..._screenings.map((s) {
              final date = DateTime.parse(s['collectionDate'] as String);
              final status = s['status'] ?? 'sent';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(AppDateUtils.formatDate(date), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Status: $status'),
                  trailing: Icon(
                    status == 'abnormal' ? Icons.error : status == 'resulted' ? Icons.check_circle : Icons.hourglass_empty,
                    color: status == 'abnormal' ? AppColors.alert : status == 'resulted' ? AppColors.success : AppColors.warning,
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddNbs, child: const Icon(Icons.add)),
    );
  }
}
