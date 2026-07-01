import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/ga_calculator.dart';
import '../../../core/utils/date_utils.dart';
import '../../../services/local_storage.dart';
import '../../babies/providers/babies_provider.dart';
import '../../babies/models/baby_model.dart';

// ─── Event model ─────────────────────────────────────────────────────────────

class CalEvent {
  final String babyId;
  final String babyName;
  final String label;
  final String type;
  final Color color;

  const CalEvent({
    required this.babyId,
    required this.babyName,
    required this.label,
    required this.type,
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

const _typeLabels = {
  'ivh':     'IVH Scan',
  'rop':     'ROP Exam',
  'echo':    'Echo',
  'mbd':     'MBD Screen',
  'hearing': 'Hearing Screen',
  'nbs':     'NBS',
};

// ─── Screen ──────────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedMonth = DateTime(
      DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDay = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  Map<DateTime, List<CalEvent>> _eventsByDay = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildEvents();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _addEvent(DateTime date, CalEvent event) {
    final key = _dateOnly(date);
    _eventsByDay.putIfAbsent(key, () => []).add(event);
  }

  void _buildEvents() {
    final babies = ref.read(babiesProvider);
    final storage = ref.read(localStorageProvider);
    final events = <DateTime, List<CalEvent>>{};
    _eventsByDay = events;

    for (final baby in babies) {
      if (baby.status == 'discharged') continue;
      _addBabyEvents(baby, storage);
    }
    setState(() {});
  }

  void _addBabyEvents(BabyModel baby, LocalStorage storage) {
    final dob = baby.dateOfBirth;
    final name = baby.firstName;

    // IVH scans (all preterms < 35w)
    if (baby.gaWeeks < 35) {
      for (final entry in {
        GACalculator.ivhFirstScanDate(dob): 'IVH Scan (72h)',
        GACalculator.ivhSecondScanDate(dob): 'IVH Scan (D7)',
        GACalculator.ivhThirdScanDate(dob): 'IVH Scan (D28)',
      }.entries) {
        _addEvent(
            entry.key,
            CalEvent(
                babyId: baby.id,
                babyName: name,
                label: entry.value,
                type: 'ivh',
                color: _typeColors['ivh']!));
      }
    }

    // ROP
    if (GACalculator.needsRopScreening(
        baby.gaWeeks, baby.birthWeightGrams)) {
      _addEvent(
          GACalculator.ropFirstScreeningDate(
              dob, baby.gaWeeks, baby.gaDays),
          CalEvent(
              babyId: baby.id,
              babyName: name,
              label: 'ROP Exam',
              type: 'rop',
              color: _typeColors['rop']!));
    }

    // Echo
    if (GACalculator.needsRoutineEcho(baby.gaWeeks)) {
      for (final entry in {
        dob.add(const Duration(days: 3)): 'Echo (D3)',
        dob.add(const Duration(days: 7)): 'Echo (D7)',
        dob.add(const Duration(days: 28)): 'Echo (D28)',
      }.entries) {
        _addEvent(
            entry.key,
            CalEvent(
                babyId: baby.id,
                babyName: name,
                label: entry.value,
                type: 'echo',
                color: _typeColors['echo']!));
      }
    }

    // MBD
    final mbdConfigs =
        storage.getScreeningsForBaby(baby.id, 'mbd_config');
    final onTpn = mbdConfigs.isNotEmpty
        ? (mbdConfigs.first['onTpnSinceBirth'] as bool? ?? false)
        : false;
    final mbdEligible = baby.gaWeeks < 30 ||
        (baby.gaWeeks <= 34 &&
            (onTpn ||
                (mbdConfigs.isNotEmpty &&
                    ((mbdConfigs.first['hasCholestasis'] as bool? ??
                            false) ||
                        (mbdConfigs.first['onBoneMeds'] as bool? ??
                            false)))));

    if (mbdEligible) {
      final firstMbd = onTpn
          ? dob.add(const Duration(days: 14))
          : dob.add(const Duration(days: 28));
      _addEvent(
          firstMbd,
          CalEvent(
              babyId: baby.id,
              babyName: name,
              label: 'MBD Screen (first)',
              type: 'mbd',
              color: _typeColors['mbd']!));

      // Next follow-up from last result
      final mbdResults =
          storage.getScreeningsForBaby(baby.id, 'mbd');
      if (mbdResults.isNotEmpty) {
        mbdResults.sort((a, b) =>
            DateTime.parse(b['screenDate'] as String)
                .compareTo(
                    DateTime.parse(a['screenDate'] as String)));
        final lastAlp =
            mbdResults.first['alp'] as int?;
        final lastPo4 =
            (mbdResults.first['phosphate'] as num?)?.toDouble();
        final canStop = lastAlp != null &&
            lastPo4 != null &&
            lastAlp < 600 &&
            lastPo4 > 4.0;
        if (!canStop) {
          final nextMbd = DateTime.parse(
                  mbdResults.first['screenDate'] as String)
              .add(const Duration(days: 14));
          if (nextMbd.isAfter(DateTime.now())) {
            _addEvent(
                nextMbd,
                CalEvent(
                    babyId: baby.id,
                    babyName: name,
                    label: 'MBD Follow-up',
                    type: 'mbd',
                    color: _typeColors['mbd']!));
          }
        }
      }
    }

    // Hearing screen (all babies — due at discharge or ~34w PMA)
    final cgaWeeks = baby.correctedGAWeeks;
    if (cgaWeeks < 37) {
      final hearingDate = dob.add(Duration(
          days: ((34 - baby.gaWeeks) * 7 - baby.gaDays)
              .clamp(7, 120)));
      _addEvent(
          hearingDate,
          CalEvent(
              babyId: baby.id,
              babyName: name,
              label: 'Hearing Screen',
              type: 'hearing',
              color: _typeColors['hearing']!));
    }

    // NBS (Day 3-5)
    _addEvent(
        dob.add(const Duration(days: 3)),
        CalEvent(
            babyId: baby.id,
            babyName: name,
            label: 'NBS Collection',
            type: 'nbs',
            color: _typeColors['nbs']!));
  }

  List<CalEvent> _eventsFor(DateTime day) =>
      _eventsByDay[_dateOnly(day)] ?? [];

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(
            _focusedMonth.year, _focusedMonth.month - 1, 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(
            _focusedMonth.year, _focusedMonth.month + 1, 1);
      });

  @override
  Widget build(BuildContext context) {
    ref.listen(babiesProvider, (_, __) => _buildEvents());

    final selectedEvents = _eventsFor(_selectedDay);
    final today = _dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () => setState(() {
              _focusedMonth = DateTime(
                  DateTime.now().year, DateTime.now().month, 1);
              _selectedDay = today;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Expanded(
                  child: Text(
                    _monthLabel(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Legend
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: _typeColors.entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: e.value, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _typeLabels[e.key] ?? e.key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Day-of-week headers
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: 6),
            child: Row(
              children: const [
                'M', 'T', 'W', 'T', 'F', 'S', 'S'
              ]
                  .map((d) => Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Calendar grid
          _CalendarGrid(
            focusedMonth: _focusedMonth,
            selectedDay: _selectedDay,
            today: today,
            eventsByDay: _eventsByDay,
            onDayTap: (day) => setState(() => _selectedDay = day),
          ),

          const Divider(height: 1),

          // Selected day header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  _selectedDay == today
                      ? 'Today — ${AppDateUtils.formatDate(_selectedDay)}'
                      : AppDateUtils.formatDate(_selectedDay),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (selectedEvents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${selectedEvents.length} event${selectedEvents.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          // Event list
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available,
                            size: 40,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No events on this day',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: selectedEvents.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final e = selectedEvents[i];
                      return _EventTile(
                        event: e,
                        onTap: () =>
                            context.go('/baby/${e.babyId}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Calendar Grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final DateTime today;
  final Map<DateTime, List<CalEvent>> eventsByDay;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.today,
    required this.eventsByDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = focusedMonth;
    // Monday = 1, so offset = weekday - 1
    final startOffset = (firstDay.weekday - 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return SizedBox(
      height: rows * 60.0,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.85,
        ),
        itemCount: rows * 7,
        itemBuilder: (ctx, index) {
          final dayNum = index - startOffset + 1;
          if (dayNum < 1 || dayNum > daysInMonth) {
            return const SizedBox.shrink();
          }
          final date = DateTime(
              focusedMonth.year, focusedMonth.month, dayNum);
          final events = eventsByDay[date] ?? [];
          final isSelected = date == selectedDay;
          final isToday = date == today;
          final isPast = date.isBefore(today);

          // Unique event type colors (max 3 dots)
          final dotColors = events
              .map((e) => e.color)
              .toSet()
              .take(3)
              .toList();

          return GestureDetector(
            onTap: () => onDayTap(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.primary.withOpacity(0.1)
                        : null,
                borderRadius: BorderRadius.circular(8),
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isPast
                              ? Colors.grey.shade400
                              : null,
                    ),
                  ),
                  if (dotColors.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dotColors
                          .map((c) => Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : c,
                                  shape: BoxShape.circle,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Event Tile ───────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final CalEvent event;
  final VoidCallback onTap;

  const _EventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: event.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: event.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: event.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: event.color),
                  ),
                  Text(
                    event.babyName,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: event.color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
