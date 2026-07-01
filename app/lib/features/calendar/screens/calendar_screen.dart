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
    final key = _dateOnly(date);
    _eventsByDay.putIfAbsent(key, () => []).add(event);
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

    // IVH scans (GA < 35w)
    if (baby.gaWeeks < 35) {
      _addEvent(GACalculator.ivhFirstScanDate(dob),
          CalEvent(babyId: baby.id, babyName: name, label: 'IVH Scan (72h)', type: 'ivh', color: _typeColors['ivh']!));
      _addEvent(GACalculator.ivhSecondScanDate(dob),
          CalEvent(babyId: baby.id, babyName: name, label: 'IVH Scan (D7)', type: 'ivh', color: _typeColors['ivh']!));
      _addEvent(GACalculator.ivhThirdScanDate(dob),
          CalEvent(babyId: baby.id, babyName: name, label: 'IVH Scan (D28)', type: 'ivh', color: _typeColors['ivh']!));
    }

    // ROP
    if (GACalculator.needsRopScreening(baby.gaWeeks, baby.birthWeightGrams)) {
      _addEvent(
        GACalculator.ropFirstScreeningDate(dob, baby.gaWeeks, baby.gaDays),
        CalEvent(babyId: baby.id, babyName: name, label: 'ROP Exam', type: 'rop', color: _typeColors['rop']!),
      );
    }

    // Echo (GA ≤ 30w)
    if (GACalculator.needsRoutineEcho(baby.gaWeeks)) {
      _addEvent(dob.add(const Duration(days: 3)),
          CalEvent(babyId: baby.id, babyName: name, label: 'Echo (D3)', type: 'echo', color: _typeColors['echo']!));
      _addEvent(dob.add(const Duration(days: 7)),
          CalEvent(babyId: baby.id, babyName: name, label: 'Echo (D7)', type: 'echo', color: _typeColors['echo']!));
      _addEvent(dob.add(const Duration(days: 28)),
          CalEvent(babyId: baby.id, babyName: name, label: 'Echo (D28)', type: 'echo', color: _typeColors['echo']!));
    }

    // MBD
    final mbdConfigs = storage.getScreeningsForBaby(baby.id, 'mbd_config');
    final cfg = mbdConfigs.isNotEmpty ? mbdConfigs.first : <String, dynamic>{};
    final onTpn = cfg['onTpnSinceBirth'] as bool? ?? false;
    final hasCholestasis = cfg['hasCholestasis'] as bool? ?? false;
    final onBoneMeds = cfg['onBoneMeds'] as bool? ?? false;
    final mbdEligible = baby.gaWeeks < 30 ||
        (baby.gaWeeks <= 34 && (onTpn || hasCholestasis || onBoneMeds));

    if (mbdEligible) {
      final firstMbd = onTpn
          ? dob.add(const Duration(days: 14))
          : dob.add(const Duration(days: 28));
      _addEvent(firstMbd,
          CalEvent(babyId: baby.id, babyName: name, label: 'MBD Screen (1st)', type: 'mbd', color: _typeColors['mbd']!));

      final mbdResults = storage.getScreeningsForBaby(baby.id, 'mbd');
      if (mbdResults.isNotEmpty) {
        mbdResults.sort((a, b) => DateTime.parse(b['screenDate'] as String)
            .compareTo(DateTime.parse(a['screenDate'] as String)));
        final lastAlp = mbdResults.first['alp'] as int?;
        final lastPo4 = (mbdResults.first['phosphate'] as num?)?.toDouble();
        final canStop = lastAlp != null && lastPo4 != null && lastAlp < 600 && lastPo4 > 4.0;
        if (!canStop) {
          final nextMbd = DateTime.parse(mbdResults.first['screenDate'] as String)
              .add(const Duration(days: 14));
          if (nextMbd.isAfter(DateTime.now())) {
            _addEvent(nextMbd,
                CalEvent(babyId: baby.id, babyName: name, label: 'MBD Follow-up', type: 'mbd', color: _typeColors['mbd']!));
          }
        }
      }
    }

    // Hearing (~34w PMA)
    if (baby.correctedGAWeeks < 37) {
      final daysToHearing = ((34 - baby.gaWeeks) * 7 - baby.gaDays).clamp(7, 120);
      _addEvent(dob.add(Duration(days: daysToHearing)),
          CalEvent(babyId: baby.id, babyName: name, label: 'Hearing Screen', type: 'hearing', color: _typeColors['hearing']!));
    }

    // NBS (D3)
    _addEvent(dob.add(const Duration(days: 3)),
        CalEvent(babyId: baby.id, babyName: name, label: 'NBS Collection', type: 'nbs', color: _typeColors['nbs']!));
  }

  List<CalEvent> _eventsFor(DateTime day) => _eventsByDay[_dateOnly(day)] ?? [];

  String _monthLabel(DateTime dt) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(babiesProvider, (_, __) => _buildEvents());

    final today = _dateOnly(DateTime.now());
    final selectedEvents = _eventsFor(_selectedDay);

    // Build the month grid data
    final firstDay = _focusedMonth;
    final startOffset = firstDay.weekday - 1; // Mon=0
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () => setState(() {
              final now = DateTime.now();
              _focusedMonth = DateTime(now.year, now.month, 1);
              _selectedDay = DateTime(now.year, now.month, now.day);
            }),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Month navigation ──────────────────────────────────
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor ?? AppColors.primary,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
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
                        fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
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

          // ── Day-of-week headers ───────────────────────────────
          Container(
            color: AppColors.primary.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((d) => Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const Divider(height: 1),

          // ── Calendar grid ─────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 58,
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

              final dotColors = events.map((e) => e.color).toSet().take(3).toList();

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
                    borderRadius: BorderRadius.circular(8),
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
                      if (dotColors.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dotColors.map((c) => Container(
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

          const Divider(height: 1),

          // ── Legend ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: _typeColors.entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: e.value, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(_typeLabels[e.key] ?? e.key,
                      style: const TextStyle(fontSize: 11)),
                ],
              )).toList(),
            ),
          ),

          const Divider(height: 1),

          // ── Selected day header ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text(
                  _selectedDay == today
                      ? 'Today — ${AppDateUtils.formatDate(_selectedDay)}'
                      : AppDateUtils.formatDate(_selectedDay),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (selectedEvents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${selectedEvents.length} event${selectedEvents.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          // ── Event tiles ───────────────────────────────────────
          if (selectedEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No screenings on this day',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            )
          else
            ...selectedEvents.map((e) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InkWell(
                onTap: () => context.go('/baby/${e.babyId}'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: e.color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: e.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.label,
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: e.color)),
                            Text(e.babyName,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: e.color.withOpacity(0.6)),
                    ],
                  ),
                ),
              ),
            )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
