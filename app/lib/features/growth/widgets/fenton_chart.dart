import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/fenton_data.dart';
import '../../../core/utils/ga_calculator.dart';
import '../../babies/models/baby_model.dart';

class FentonChart extends StatelessWidget {
  final BabyModel baby;
  final List<Map<String, dynamic>> measurements;
  final String type; // 'weight', 'hc', 'length'

  const FentonChart({
    super.key,
    required this.baby,
    required this.measurements,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final refData = _getReferenceData();
    final weeks = refData.keys.toList()..sort();
    final minWeek = weeks.first;
    final maxWeek = weeks.last;

    final percentileLines = _buildPercentileLines(refData, weeks);
    final babyLine = _buildBabyLine();

    return LineChart(
      LineChartData(
        minX: minWeek,
        maxX: maxWeek,
        minY: _getMinY(refData),
        maxY: _getMaxY(refData),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _gridInterval,
          verticalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Gestational Age (weeks)',
                style: TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                if (value % 2 != 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(_yAxisLabel,
                style: const TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: _gridInterval,
              getTitlesWidget: (value, meta) {
                return Text(
                  type == 'weight'
                      ? '${value.toInt()}'
                      : value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey.shade400),
            bottom: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        lineBarsData: [...percentileLines, if (babyLine != null) babyLine],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                if (spot.barIndex == percentileLines.length) {
                  return LineTooltipItem(
                    'CGA: ${spot.x.toStringAsFixed(1)}w\n${_valueLabel}: ${spot.y.toStringAsFixed(type == "weight" ? 0 : 1)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Map<double, Map<String, double>> _getReferenceData() {
    switch (type) {
      case 'weight':
        return FentonData.getWeightData(baby.sex);
      case 'hc':
        return FentonData.getHCData(baby.sex);
      case 'length':
        return FentonData.getLengthData(baby.sex);
      default:
        return FentonData.getWeightData(baby.sex);
    }
  }

  List<LineChartBarData> _buildPercentileLines(
    Map<double, Map<String, double>> refData,
    List<double> weeks,
  ) {
    final percentiles = ['P3', 'P10', 'P50', 'P90', 'P97'];
    final colors = [
      Colors.red.shade300,
      Colors.orange.shade300,
      Colors.green.shade600,
      Colors.orange.shade300,
      Colors.red.shade300,
    ];

    return List.generate(percentiles.length, (i) {
      return LineChartBarData(
        spots: weeks.map((w) {
          final val = refData[w]?[percentiles[i]];
          return val != null ? FlSpot(w, val) : null;
        }).whereType<FlSpot>().toList(),
        isCurved: true,
        curveSmoothness: 0.3,
        color: colors[i].withOpacity(0.6),
        barWidth: percentiles[i] == 'P50' ? 2 : 1,
        dotData: const FlDotData(show: false),
        dashArray: percentiles[i] == 'P50' ? null : [5, 3],
        belowBarData: BarAreaData(show: false),
      );
    });
  }

  LineChartBarData? _buildBabyLine() {
    if (measurements.isEmpty) return null;

    final dataKey = type == 'hc' ? 'headCircumference' : type;
    final spots = <FlSpot>[];

    for (final m in measurements) {
      final value = m[dataKey];
      final cgaWeeks = m['correctedGAWeeks'];
      if (value != null && cgaWeeks != null) {
        spots.add(FlSpot(
          (cgaWeeks as num).toDouble(),
          (value as num).toDouble(),
        ));
      }
    }

    if (spots.isEmpty) return null;

    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.2,
      color: AppColors.primary,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 5,
            color: AppColors.primary,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  double _getMinY(Map<double, Map<String, double>> data) {
    double min = double.infinity;
    for (final entry in data.values) {
      final p3 = entry['P3'] ?? double.infinity;
      if (p3 < min) min = p3;
    }
    return (min * 0.8).floorToDouble();
  }

  double _getMaxY(Map<double, Map<String, double>> data) {
    double max = 0;
    for (final entry in data.values) {
      final p97 = entry['P97'] ?? 0;
      if (p97 > max) max = p97;
    }
    return (max * 1.1).ceilToDouble();
  }

  double get _gridInterval {
    switch (type) {
      case 'weight':
        return 500;
      case 'hc':
        return 5;
      case 'length':
        return 5;
      default:
        return 500;
    }
  }

  String get _yAxisLabel {
    switch (type) {
      case 'weight':
        return 'Weight (g)';
      case 'hc':
        return 'Head Circumference (cm)';
      case 'length':
        return 'Length (cm)';
      default:
        return '';
    }
  }

  String get _valueLabel {
    switch (type) {
      case 'weight':
        return 'Weight';
      case 'hc':
        return 'HC';
      case 'length':
        return 'Length';
      default:
        return '';
    }
  }
}
