import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/ga_calculator.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/local_storage.dart';
import '../../babies/providers/babies_provider.dart';

class EventsScreen extends ConsumerStatefulWidget {
  final String babyId;
  const EventsScreen({super.key, required this.babyId});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final storage = ref.read(localStorageProvider);
    _events = storage.getEventsForBaby(widget.babyId)
      ..sort((a, b) => DateTime.parse(b['eventDate'] as String)
          .compareTo(DateTime.parse(a['eventDate'] as String)));
    setState(() {});
  }

  void _showAddEvent() {
    String category = 'procedure';
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final performedByC = TextEditingController();
    final outcomeC = TextEditingController();
    DateTime eventDate = DateTime.now();

    final categories = [
      'procedure', 'complication', 'diagnosis', 'transfusion',
      'surgery', 'transfer', 'family-meeting',
    ];

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
                const Text('Add Clinical Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: ctx, initialDate: eventDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (p != null) ss(() => eventDate = p);
                  },
                  child: InputDecorator(decoration: const InputDecoration(labelText: 'Event Date'), child: Text('${eventDate.day}/${eventDate.month}/${eventDate.year}')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(value: category, decoration: const InputDecoration(labelText: 'Category'), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) ss(() => category = v); }),
                const SizedBox(height: 12),
                TextFormField(controller: titleC, decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. Lumbar puncture, Blood transfusion')),
                const SizedBox(height: 12),
                TextFormField(controller: descC, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true)),
                const SizedBox(height: 12),
                TextFormField(controller: performedByC, decoration: const InputDecoration(labelText: 'Performed By')),
                const SizedBox(height: 12),
                TextFormField(controller: outcomeC, decoration: const InputDecoration(labelText: 'Outcome')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (titleC.text.trim().isEmpty) return;
                    final baby = ref.read(babyProvider(widget.babyId));
                    final storage = ref.read(localStorageProvider);
                    storage.saveEvent({
                      'id': const Uuid().v4(),
                      'babyId': widget.babyId,
                      'eventDate': eventDate.toIso8601String(),
                      'dayOfLife': baby != null ? GACalculator.dayOfLife(baby.dateOfBirth, eventDate) : 0,
                      'category': category,
                      'title': titleC.text.trim(),
                      'description': descC.text.trim(),
                      'performedBy': performedByC.text.trim(),
                      'outcome': outcomeC.text.trim(),
                    });
                    _loadEvents();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'procedure': return Icons.medical_services;
      case 'complication': return Icons.warning;
      case 'diagnosis': return Icons.assignment;
      case 'transfusion': return Icons.bloodtype;
      case 'surgery': return Icons.local_hospital;
      case 'transfer': return Icons.swap_horiz;
      case 'family-meeting': return Icons.people;
      default: return Icons.event_note;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'procedure': return AppColors.primary;
      case 'complication': return AppColors.alert;
      case 'diagnosis': return AppColors.secondary;
      case 'transfusion': return const Color(0xFFD32F2F);
      case 'surgery': return AppColors.warning;
      case 'transfer': return Colors.purple;
      case 'family-meeting': return Colors.teal;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Events')),
      body: ListView(
        children: [
          const SectionHeader(title: 'Timeline'),
          if (_events.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No events recorded', style: TextStyle(color: Colors.grey.shade500))))
          else
            ..._events.map((e) {
              final date = DateTime.parse(e['eventDate'] as String);
              final cat = e['category'] as String? ?? 'procedure';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _categoryColor(cat).withOpacity(0.15),
                    child: Icon(_categoryIcon(cat), color: _categoryColor(cat), size: 20),
                  ),
                  title: Text(e['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppDateUtils.formatDate(date)} • DOL ${e['dayOfLife']}'),
                      Text(cat, style: TextStyle(color: _categoryColor(cat), fontSize: 12, fontWeight: FontWeight.w500)),
                      if (e['description'] != null && (e['description'] as String).isNotEmpty)
                        Text(e['description'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddEvent, child: const Icon(Icons.add)),
    );
  }
}
