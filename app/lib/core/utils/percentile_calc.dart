import '../constants/fenton_data.dart';

class PercentileCalculator {
  PercentileCalculator._();

  static double? calculatePercentile({
    required double cgaWeeks,
    required double value,
    required Map<double, Map<String, double>> referenceData,
  }) {
    if (cgaWeeks < 22 || cgaWeeks > 50) return null;

    final lowerWeek = cgaWeeks.floor().toDouble();
    final upperWeek = (cgaWeeks.ceil()).toDouble();
    final fraction = cgaWeeks - lowerWeek;

    final lowerData = referenceData[lowerWeek];
    final upperData = referenceData[upperWeek];
    if (lowerData == null || upperData == null) return null;

    Map<String, double> interpolated;
    if (lowerWeek == upperWeek) {
      interpolated = lowerData;
    } else {
      interpolated = {};
      for (final key in lowerData.keys) {
        final lv = lowerData[key]!;
        final uv = upperData[key]!;
        interpolated[key] = lv + (uv - lv) * fraction;
      }
    }

    final p3 = interpolated['P3']!;
    final p10 = interpolated['P10']!;
    final p50 = interpolated['P50']!;
    final p90 = interpolated['P90']!;
    final p97 = interpolated['P97']!;

    if (value <= p3) return 3.0 * (value / p3);
    if (value <= p10) return 3.0 + 7.0 * ((value - p3) / (p10 - p3));
    if (value <= p50) return 10.0 + 40.0 * ((value - p10) / (p50 - p10));
    if (value <= p90) return 50.0 + 40.0 * ((value - p50) / (p90 - p50));
    if (value <= p97) return 90.0 + 7.0 * ((value - p90) / (p97 - p90));
    return 97.0 + 3.0 * ((value - p97) / (p97 * 0.1));
  }

  static String percentileBand({
    required double cgaWeeks,
    required double value,
    required Map<double, Map<String, double>> referenceData,
  }) {
    final percentile =
        calculatePercentile(cgaWeeks: cgaWeeks, value: value, referenceData: referenceData);
    if (percentile == null) return 'N/A';
    if (percentile < 3) return '<3rd';
    if (percentile < 10) return '3rd-10th';
    if (percentile < 50) return '10th-50th';
    if (percentile < 90) return '50th-90th';
    if (percentile < 97) return '90th-97th';
    return '>97th';
  }

  static double? getPercentileValue({
    required double cgaWeeks,
    required String percentile,
    required Map<double, Map<String, double>> referenceData,
  }) {
    if (cgaWeeks < 22 || cgaWeeks > 50) return null;

    final lowerWeek = cgaWeeks.floor().toDouble();
    final upperWeek = cgaWeeks.ceil().toDouble();
    final fraction = cgaWeeks - lowerWeek;

    final lowerData = referenceData[lowerWeek];
    final upperData = referenceData[upperWeek];
    if (lowerData == null || upperData == null) return null;

    final lv = lowerData[percentile];
    final uv = upperData[percentile];
    if (lv == null || uv == null) return null;

    return lv + (uv - lv) * fraction;
  }
}
