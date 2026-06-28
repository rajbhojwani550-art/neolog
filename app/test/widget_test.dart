import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gestational age calculation', () {
    final dob = DateTime(2024, 1, 1);
    final today = DateTime(2024, 1, 29);
    const gaWeeks = 28;
    const gaDays = 3;

    final totalDaysAtBirth = gaWeeks * 7 + gaDays;
    final daysLived = today.difference(dob).inDays;
    final totalDays = totalDaysAtBirth + daysLived;
    final cga = '${totalDays ~/ 7}+${totalDays % 7}';

    expect(cga, '32+3');
    expect(daysLived, 28);
  });

  test('Day of life calculation', () {
    final dob = DateTime(2024, 6, 1);
    final today = DateTime(2024, 6, 1);
    final dol = today.difference(dob).inDays + 1;
    expect(dol, 1);

    final day10 = DateTime(2024, 6, 10);
    final dol10 = day10.difference(dob).inDays + 1;
    expect(dol10, 10);
  });

  test('Preterm classification', () {
    expect(_isPreterm(24, 0), true);
    expect(_isPreterm(28, 3), true);
    expect(_isPreterm(34, 0), true);
    expect(_isPreterm(36, 6), true);
    expect(_isPreterm(37, 0), false);
    expect(_isPreterm(40, 0), false);
  });

  test('ROP screening eligibility', () {
    expect(_needsRop(28, 900), true);
    expect(_needsRop(34, 1800), true);
    expect(_needsRop(35, 1900), true);
    expect(_needsRop(35, 2100), false);
  });
}

bool _isPreterm(int weeks, int days) => (weeks * 7 + days) < (37 * 7);

bool _needsRop(int gaWeeks, int birthWeight) =>
    gaWeeks <= 34 || birthWeight <= 2000;
