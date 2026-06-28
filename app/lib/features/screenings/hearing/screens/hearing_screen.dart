import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../services/local_storage.dart';

class HearingScreen extends ConsumerStatefulWidget {
  final String babyId;
  const HearingScreen({super.key, required this.babyId});

  @override
  ConsumerState<HearingScreen> createState() => _HearingScreenState();
}

class _HearingScreenState extends ConsumerState<HearingScreen> {
  List<Map<String, dynamic>> _screenings = [];

  @override
  void initState() {
    super.initState();
    _loadScreenings();
  }

  void _loadScreenings() {
    final storage = ref.read(localStorageProvider);
    _screenings = storage.getScreeningsForBaby(widget.babyId, 'hearing')
      ..sort((a, b) => DateTime.parse(b['screenDate'] as String)
          .compareTo(DateTime.parse(a['screenDate'] as String)));
    setState(() {});
  }

  void _showAddScreen() {
    String method = 'OAE', rightEar = 'pass', leftEar = 'pass';
    final notesC = TextEditingController();
    DateTime screenDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Hearing Screen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(context: ctx, initialDate: screenDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (p != null) ss(() => screenDate = p);
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Screen Date'), child: Text('${screenDate.day}/${screenDate.month}/${screenDate.year}')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(value: method, decoration: const InputDecoration(labelText: 'Method'), items: ['OAE', 'AABR'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) { if (v != null) ss(() => method = v); }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: DropdownButtonFormField(value: rightEar, decoration: const InputDecoration(labelText: 'Right Ear'), items: ['pass', 'refer'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) { if (v != null) ss(() => rightEar = v); })),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField(value: leftEar, decoration: const InputDecoration(labelText: 'Left Ear'), items: ['pass', 'refer'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) { if (v != null) ss(() => leftEar = v); })),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: notesC, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final storage = ref.read(localStorageProvider);
                  storage.saveScreening('hearing', {
                    'id': const Uuid().v4(),
                    'babyId': widget.babyId,
                    'screenDate': screenDate.toIso8601String(),
                    'method': method,
                    'rightEar': rightEar,
                    'leftEar': leftEar,
                    'notes': notesC.text,
                  });
                  _loadScreenings();
                  Navigator.pop(ctx);
                },
                child: const Text('Save Screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hearing Screen')),
      body: ListView(
        children: [
          const SectionHeader(title: 'Screen History'),
          if (_screenings.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No hearing screens', style: TextStyle(color: Colors.grey.shade500))))
          else
            ..._screenings.map((s) {
              final date = DateTime.parse(s['screenDate'] as String);
              final re = s['rightEar'] ?? 'pass';
              final le = s['leftEar'] ?? 'pass';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(AppDateUtils.formatDate(date), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Method: ${s['method']} • RE: $re • LE: $le'),
                  trailing: Icon(
                    re == 'pass' && le == 'pass' ? Icons.check_circle : Icons.warning,
                    color: re == 'pass' && le == 'pass' ? AppColors.success : AppColors.warning,
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddScreen, child: const Icon(Icons.add)),
    );
  }
}
