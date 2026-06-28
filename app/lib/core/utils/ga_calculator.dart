class GACalculator {
  GACalculator._();

  static String computeCGA(
      DateTime dob, int gaWeeks, int gaDays, DateTime today) {
    final totalDaysAtBirth = gaWeeks * 7 + gaDays;
    final daysLived = today.difference(dob).inDays;
    final totalDays = totalDaysAtBirth + daysLived;
    return '${totalDays ~/ 7}+${totalDays % 7}';
  }

  static double cgaInWeeks(DateTime dob, int gaWeeks, int gaDays, DateTime today) {
    final totalDaysAtBirth = gaWeeks * 7 + gaDays;
    final daysLived = today.difference(dob).inDays;
    final totalDays = totalDaysAtBirth + daysLived;
    return totalDays / 7.0;
  }

  static int dayOfLife(DateTime dob, DateTime today) {
    return today.difference(dob).inDays + 1;
  }

  static ({int weeks, int days}) parseGA(String ga) {
    final parts = ga.split('+');
    if (parts.length != 2) return (weeks: 0, days: 0);
    return (
      weeks: int.tryParse(parts[0]) ?? 0,
      days: int.tryParse(parts[1]) ?? 0,
    );
  }

  static String formatGA(int totalDays) {
    return '${totalDays ~/ 7}+${totalDays % 7}';
  }

  static bool isPreterm(int gaWeeks, int gaDays) {
    return (gaWeeks * 7 + gaDays) < (37 * 7);
  }

  static bool isTerm(int gaWeeks, int gaDays) {
    return (gaWeeks * 7 + gaDays) >= (37 * 7);
  }

  static String pretermCategory(int gaWeeks) {
    if (gaWeeks < 28) return 'Extremely Preterm';
    if (gaWeeks < 32) return 'Very Preterm';
    if (gaWeeks < 34) return 'Moderate Preterm';
    if (gaWeeks < 37) return 'Late Preterm';
    return 'Term';
  }

  // ROP screening: first exam at 4 weeks of life OR 31 weeks CGA, whichever is LATER
  static DateTime ropFirstScreeningDate(
      DateTime dob, int gaWeeks, int gaDays) {
    final fourWeeksDate = dob.add(const Duration(days: 28));
    final totalDaysAtBirth = gaWeeks * 7 + gaDays;
    final daysTo31Weeks = (31 * 7) - totalDaysAtBirth;
    final cga31WeeksDate = dob.add(Duration(days: daysTo31Weeks));
    return fourWeeksDate.isAfter(cga31WeeksDate)
        ? fourWeeksDate
        : cga31WeeksDate;
  }

  static bool needsRopScreening(int gaWeeks, int birthWeightGrams) {
    return gaWeeks <= 34 || birthWeightGrams <= 2000;
  }

  // IVH screening milestones
  static DateTime ivhFirstScanDate(DateTime dob) {
    return dob.add(const Duration(hours: 72));
  }

  static DateTime ivhSecondScanDate(DateTime dob) {
    return dob.add(const Duration(days: 7));
  }

  static DateTime ivhThirdScanDate(DateTime dob) {
    return dob.add(const Duration(days: 28));
  }

  // Echo: Day 3, 7, 28 for ≤30 weeks
  static bool needsRoutineEcho(int gaWeeks) {
    return gaWeeks <= 30;
  }
}
