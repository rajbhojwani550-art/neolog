import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/fenton_data.dart';
import '../../../core/utils/ga_calculator.dart';
import '../../babies/models/baby_model.dart';

class FentonChart extends StatefulWidget {
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
  State<FentonChart> createState() => _FentonChartState();
}

class _FentonChartState extends State<FentonChart> {
  bool _fullRange = false;

  @override
  Widget build(BuildContext context) {
    final refData = _getReferenceData();
    final allWeeks = refData.keys.toList()..sort();

    // Current CGA of the baby
    final currentCGA = widget.baby.correctedGAWeeks;
    final birthGA = widget.baby.gaWeeks + widget.baby.gaDays / 7.0;
    final isUnder28Days = widget.baby.dayOfLife <= 28;

    // Focused window: birth GA - 2 to current CGA + 10 (or full range)
    final focusMin = (_fullRange ? 22.0 : (birthGA - 2).clamp(22.0, 44.0)).floorToDouble();
    final focusMax = (_fullRange ? 50.0 : (currentCGA + 10).clamp(28.0, 50.0)).ceilToDouble();

    // Only include weeks within the visible window
    final visibleWeeks = allWeeks.where((w) => w >= focusMin && w <= focusMax).toList();

    final percentileLines = _buildPercentileLines(refData, visibleWeeks);
    final babyLine = _buildBabyLine();

    // Y-axis range: derived from P3 min to P97 max within visible window only
    final minY = _getMinYForRange(refData, focusMin, focusMax);
    final maxY = _getMaxYForRange(refData, focusMin, focusMax);

    // 28-day milestone CGA line
    final day28CGA = birthGA + 4.0; // 28 days = 4 weeks

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              LineChart(
                LineChartData(
                  minX: focusMin,
                  maxX: focusMax,
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _gridInterval(maxY - minY),
                    verticalInterval: _fullRange ? 4 : 2,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('CGA (weeks)',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _fullRange ? 4 : 2,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value % (_fullRange ? 4 : 2) != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${value.toInt()}w',
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: _gridInterval(maxY - minY),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            widget.type == 'weight'
                                ? value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(1)}k'
                                    : '${value.toInt()}'
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
                  extraLinesData: ExtraLinesData(
                    verticalLines: [
                      // Birth line
                      VerticalLine(
                        x: birthGA,
                        color: AppColors.secondary.withOpacity(0.7),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                        label: VerticalLineLabel(
                          show: true,
                          alignment: Alignment.topLeft,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                          labelResolver: (_) => 'Birth',
                        ),
                      ),
                      // 28-day milestone line (if visible and baby ≤ 28 DOL)
                      if (day28CGA <= focusMax && day28CGA >= focusMin)
                        VerticalLine(
                          x: day28CGA,
                          color: AppColors.warning.withOpacity(0.7),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                          label: VerticalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                            labelResolver: (_) => 'Day 28',
                          ),
                        ),
                      // Current CGA line
                      VerticalLine(
                        x: currentCGA.clamp(focusMin, focusMax),
                        color: AppColors.primary.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [3, 3],
                        label: VerticalLineLabel(
                          show: true,
                          alignment: Alignment.bottomRight,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.primary,
                          ),
                          labelResolver: (_) => 'Now',
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    ...percentileLines,
                    if (babyLine != null) babyLine,
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final isPatient = babyLine != null &&
                              spot.barIndex == percentileLines.length;
                          if (!isPatient) {
                            // Show percentile label
                            final labels = ['P3', 'P10', 'P50', 'P90', 'P97'];
                            if (spot.barIndex < labels.length) {
                              return LineTooltipItem(
                                labels[spot.barIndex],
                                TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              );
                            }
                            return null;
                          }
                          final val = widget.type == 'weight'
                              ? '${spot.y.toStringAsFixed(0)}g'
                              : '${spot.y.toStringAsFixed(1)} cm';
                          return LineTooltipItem(
                            'CGA ${spot.x.toStringAsFixed(1)}w\n$val',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
              // Percentile legend overlay
              Positioned(
                top: 8,
                right: 8,
                child: _PercentileLegend(),
              ),
            ],
          ),
        ),
        // Controls row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              if (isUnder28Days)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline, size: 12, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text('< 28 days old',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _fullRange = !_fullRange),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fullRange ? 'Zoom in' : 'Full range (22–50w)',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<double, Map<String, double>> _getReferenceData() {
    switch (widget.type) {
      case 'weight':
        return FentonData.getWeightData(widget.baby.sex);
      case 'hc':
        return FentonData.getHCData(widget.baby.sex);
      case 'length':
        return FentonData.getLengthData(widget.baby.sex);
      default:
        return FentonData.getWeightData(widget.baby.sex);
    }
  }

  List<LineChartBarData> _buildPercentileLines(
    Map<double, Map<String, double>> refData,
    List<double> weeks,
  ) {
    const percentiles = ['P3', 'P10', 'P50', 'P90', 'P97'];
    final colors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.green.shade600,
      Colors.orange.shade400,
      Colors.red.shade400,
    ];

    return List.generate(percentiles.length, (i) {
      final spots = weeks.map((w) {
        final val = refData[w]?[percentiles[i]];
        return val != null ? FlSpot(w, val) : null;
      }).whereType<FlSpot>().toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.25,
        color: colors[i].withOpacity(0.65),
        barWidth: percentiles[i] == 'P50' ? 2.5 : 1.5,
        dotData: const FlDotData(show: false),
        dashArray: percentiles[i] == 'P50' ? null : [6, 3],
        belowBarData: BarAreaData(show: false),
      );
    });
  }

  LineChartBarData? _buildBabyLine() {
    if (widget.measurements.isEmpty) return null;

    final dataKey = widget.type == 'hc' ? 'headCircumference' : widget.type;
    final spots = <FlSpot>[];

    for (final m in widget.measurements) {
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
      isCurved: spots.length > 2,
      curveSmoothness: 0.2,
      color: AppColors.primary,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 6,
          color: AppColors.primary,
          strokeWidth: 2.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  double _getMinYForRange(
      Map<double, Map<String, double>> data, double minX, double maxX) {
    double min = double.infinity;
    for (final entry in data.entries) {
      if (entry.key >= minX && entry.key <= maxX) {
        final p3 = entry.value['P3'] ?? double.infinity;
        if (p3 < min) min = p3;
      }
    }
    if (min == double.infinity) min = 0;

    // Also account for any baby measurements below P3
    for (final m in widget.measurements) {
      final dataKey = widget.type == 'hc' ? 'headCircumference' : widget.type;
      final val = (m[dataKey] as num?)?.toDouble();
      if (val != null && val < min) min = val;
    }
    return (min * 0.85).floorToDouble();
  }

  double _getMaxYForRange(
      Map<double, Map<String, double>> data, double minX, double maxX) {
    double max = 0;
    for (final entry in data.entries) {
      if (entry.key >= minX && entry.key <= maxX) {
        final p97 = entry.value['P97'] ?? 0;
        if (p97 > max) max = p97;
      }
    }
    return (max * 1.1).ceilToDouble();
  }

  double _gridInterval(double range) {
    if (widget.type == 'weight') {
      if (range <= 1000) return 100;
      if (range <= 2000) return 250;
      if (range <= 5000) return 500;
      return 1000;
    }
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    return 10;
  }
}

class _PercentileLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('P97/P3', Colors.red.shade400),
      ('P90/P10', Colors.orange.shade400),
      ('P50', Colors.green.shade600),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 2,
                  color: item.$2,
                ),
                const SizedBox(width: 4),
                Text(item.$1,
                    style: TextStyle(
                        fontSize: 9,
                        color: item.$2,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
