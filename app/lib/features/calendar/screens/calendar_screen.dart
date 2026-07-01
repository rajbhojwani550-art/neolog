import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/ga_calculator.dart';
import '../../../core/utils/date_utils.dart';
import '../../../services/local_storage.dart';
import '../../babies/providers/babies_provider.dart';
import '../../babies/models/baby_model.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class CalEvent {
  final String babyId;
  final String babyName;
  final String label;
  final Color color;
  const CalEvent({
    required this.babyId,
    required this.babyName,
    required this.label,
    required this.color,
  });
}

const _typeColors = {
  'ivh':     Color(0xFF7B1FA2),
  'rop':     Color(0xFF1565C0),
  'echo':    Color(0xFFC62828),
  'mbd':     Color(0xFF5D4037),
  'hearing': Color(0xFF00796B),
  'nbs':     Color(0xFF388E3C),
};

// ─── Screen ──────────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;
  Map<DateTime, List<CalEvent>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildEvents();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _addEvent(DateTime date, CalEvent event) {
    _eventsByDay.putIfAbsent(_dateOnly(date), () => []).add(event);
  }

  void _buildEvents() {
    final babies = ref.read(babiesProvider);
    final storage = ref.read(localStorageProvider);
    _eventsByDay = {};
    for (final baby in babies) {
      if (baby.status == 'discharged') continue;
      _addBabyEvents(baby, storage);
    }
    if (mounted) setState(() {});
  }

  void _addBabyEvents(BabyModel baby, LocalStorage storage) {
    final dob = baby.dateOfBirth;
    final name = baby.firstName;

    // IVH (GA < 35w)
    if (baby.gaWeeks < 35) {
      _addEvent(GACalculator.ivhFirstScanDate(dob),
          CalEvent(babyId: baby.id, babyName: name, label: 'IVH Scan (72h)', color: _typeColors['ivh']!));
      _addEvent(GACalculator.ivhSecondScanDate(dob),
          CalEvent(babyId: baby.id, babyName: name, label: 'IVH Scan (D7)', color: _typeColors['ivh']!));
      _addEvent(GACalculator.ivhThirdScanDate(dob),
          CalEvent(babyId: baby.id, babyName: name, label: 'IVH Scan (D28)', color: _typeColors['ivh']!));
    }

    // ROP
    if (GACalculator.needsRopScreening(baby.gaWeeks, baby.birthWeightGrams)) {
      _addEvent(
        GACalculator.ropFirstScreeningDate(dob, baby.gaWeeks, baby.gaDays),
        CalEvent(babyId: baby.id, babyName: name, label: 'ROP Exam', color: _typeColors['rop']!),
      );
    }

    // Echo (GA ≤ 30w)
    if (GACalculator.needsRoutineEcho(baby.gaWeeks)) {
      _addEvent(dob.add(const Duration(days: 3)),
          CalEvent(babyId: baby.id, babyName: name, label: 'Echo (D3)', color: _typeColors['echo']!));
      _addEvent(dob.add(const Duration(days: 7)),
          CalEvent(babyId: baby.id, babyName: name, label: 'Echo (D7)', color: _typeColors['echo']!));
      _addEvent(dob.add(const Duration(days: 28)),
          CalEvent(babyId: baby.id, babyName: name, label: 'Echo (D28)', color: _typeColors['echo']!));
    }

    // MBD
    final cfgs = storage.getScreeningsForBaby(baby.id, 'mbd_config');
    final cfg = cfgs.isNotEmpty ? cfgs.first : <String, dynamic>{};
    final onTpn = cfg['onTpnSinceBirth'] as bool? ?? false;
    final mbdEligible = baby.gaWeeks < 30 ||
        (baby.gaWeeks <= 34 &&
            (onTpn ||
                (cfg['hasCholestasis'] as bool? ?? false) ||
                (cfg['onBoneMeds'] as bool? ?? false)));
    if (mbdEligible) {
      final firstMbd = onTpn
          ? dob.add(const Duration(days: 14))
          : dob.add(const Duration(days: 28));
      _addEvent(firstMbd,
          CalEvent(babyId: baby.id, babyName: name, label: 'MBD Screen (1st)', color: _typeColors['mbd']!));
      final mbdResults = storage.getScreeningsForBaby(baby.id, 'mbd');
      if (mbdResults.isNotEmpty) {
        mbdResults.sort((a, b) => DateTime.parse(b['screenDate'] as String)
            .compareTo(DateTime.parse(a['screenDate'] as String)));
        final lastAlp = mbdResults.first['alp'] as int?;
        final lastPo4 = (mbdResults.first['phosphate'] as num?)?.toDouble();
        final canStop = lastAlp != null && lastPo4 != null && lastAlp < 600 && lastPo4 > 4.0;
        if (!canStop) {
          final next = DateTime.parse(mbdResults.first['screenDate'] as String)
              .add(const Duration(days: 14));
          if (next.isAfter(DateTime.now())) {
            _addEvent(next, CalEvent(babyId: baby.id, babyName: name, label: 'MBD Follow-up', color: _typeColors['mbd']!));
          }
        }
      }
    }

    // Hearing (~34w PMA)
    if (baby.correctedGAWeeks < 37) {
      final days = ((34 - baby.gaWeeks) * 7 - baby.gaDays).clamp(7, 120);
      _addEvent(dob.add(Duration(days: days)),
          CalEvent(babyId: baby.id, babyName: name, label: 'Hearing Screen', color: _typeColors['hearing']!));
    }

    // NBS (D3)
    _addEvent(dob.add(const Duration(days: 3)),
        CalEvent(babyId: baby.id, babyName: name, label: 'NBS Collection', color: _typeColors['nbs']!));
  }

  List<CalEvent> _eventsFor(DateTime day) => _eventsByDay[_dateOnly(day)] ?? [];

  @override
  Widget build(BuildContext context) {
    ref.listen(babiesProvider, (_, __) => _buildEvents());

    final today = _dateOnly(DateTime.now());
    final selectedEvents = _eventsFor(_selectedDay);

    // Grid dimensions
    final startOffset = _focusedMonth.weekday - 1; // Mon = 0
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final rows = ((startOffset + daysInMonth) / 7).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () => setState(() {
              final now = DateTime.now();
              _focusedMonth = DateTime(now.year, now.month, 1);
              _selectedDay = DateTime(now.year, now.month, now.day);
            }),
          ),
        ],
      ),
      // ── Split layout: calendar top, events panel bottom ──────
      body: Column(
        children: [
          // ── Calendar section (sizes itself, never scrolls) ────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Month nav
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                      }),
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(_focusedMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                      }),
                    ),
                  ],
                ),
              ),

              // Day-of-week headers
              Container(
                color: AppColors.primary.withOpacity(0.06),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => Expanded(
                            child: Text(d,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade600)),
                          ))
                      .toList(),
                ),
              ),

              const Divider(height: 1),

              // Month grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 48,
                ),
                itemCount: rows * 7,
                itemBuilder: (ctx, index) {
                  final dayNum = index - startOffset + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                  final events = _eventsFor(date);
                  final isSelected = _dateOnly(date) == _dateOnly(_selectedDay);
                  final isToday = _dateOnly(date) == today;
                  final isPast = date.isBefore(today) && !isToday;
                  final dots = events.map((e) => e.color).toSet().take(3).toList();

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = date),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                                ? AppColors.primary.withOpacity(0.12)
                                : null,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : isPast
                                      ? Colors.grey.shade400
                                      : null,
                            ),
                          ),
                          if (dots.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: dots.map((c) => Container(
                                width: 5, height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : c,
                                  shape: BoxShape.circle,
                                ),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: _typeColors.entries.map((e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7,
                          decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Text(_labelFor(e.key), style: const TextStyle(fontSize: 10)),
                    ],
                  )).toList(),
                ),
              ),
            ],
          ),

          const Divider(height: 1),

          // ── Events panel (fills the rest of the screen) ───────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected day header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDay == today ? 'Today' : _weekdayLabel(_selectedDay),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500),
                          ),
                          Text(
                            AppDateUtils.formatDate(_selectedDay),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (selectedEvents.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedEvents.length} screening${selectedEvents.length == 1 ? '' : 's'} due',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Event list
                Expanded(
                  child: selectedEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_available,
                                  size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text('No screenings on this day',
                                  style: TextStyle(
                                      color: Colors.grey.shade400, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          itemCount: selectedEvents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final e = selectedEvents[i];
                            return InkWell(
                              onTap: () => context.go('/baby/${e.babyId}'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: e.color.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: e.color.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: e.color.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(_iconFor(e.label), size: 18, color: e.color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.label,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: e.color)),
                                          const SizedBox(height: 2),
                                          Text(e.babyName,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right,
                                        size: 18, color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime dt) {
    const m = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${m[dt.month - 1]} ${dt.year}';
  }

  String _weekdayLabel(DateTime dt) {
    const d = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return d[dt.weekday - 1];
  }

  String _labelFor(String type) {
    const labels = {
      'ivh': 'IVH', 'rop': 'ROP', 'echo': 'Echo',
      'mbd': 'MBD', 'hearing': 'Hearing', 'nbs': 'NBS',
    };
    return labels[type] ?? type;
  }

  IconData _iconFor(String label) {
    if (label.contains('IVH')) return Icons.view_in_ar;
    if (label.contains('ROP')) return Icons.visibility;
    if (label.contains('Echo')) return Icons.favorite;
    if (label.contains('MBD')) return Icons.science;
    if (label.contains('Hearing')) return Icons.hearing;
    if (label.contains('NBS')) return Icons.bloodtype;
    return Icons.medical_services;
  }
}
