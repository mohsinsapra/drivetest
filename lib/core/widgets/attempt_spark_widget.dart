import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AttemptCountLineGraph extends StatelessWidget {
  final Map<String, int> data;
  final Color lineColor;
  final double height;

  const AttemptCountLineGraph({
    super.key,
    required this.data,
    this.lineColor = Colors.blue,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    final values = data.values.toList();

    final spots = List.generate(
        values.length, (i) => FlSpot(i.toDouble(), values[i].toDouble()));

    final maxVal =
        values.isEmpty ? 5 : values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal + 1).toDouble().clamp(3.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,

            // ── Scrubber / crosshair interaction ──────────────────────────
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              // Large threshold so a finger anywhere on the chart snaps to
              // the nearest data point — feels fluid while dragging
              touchSpotThreshold: 44,

              // Vertical crosshair line + dot at the touched point
              getTouchedSpotIndicator:
                  (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    // Dashed vertical line running from bottom to the spot
                    FlLine(
                      color: lineColor.withValues(alpha: 0.55),
                      strokeWidth: 1.5,
                      dashArray: [5, 4],
                    ),
                    // Highlighted dot at the intersection
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, idx) =>
                          FlDotCirclePainter(
                        radius: 5,
                        color: lineColor,
                        strokeWidth: 2.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                  );
                }).toList();
              },

              // Tooltip bubble shown above the touched point
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => lineColor.withValues(alpha: 0.9),
                tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 5),
                tooltipMargin: 10,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (touchedSpots) =>
                    touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final label =
                      idx >= 0 && idx < keys.length ? keys[idx] : '';
                  final count = spot.y.toInt();
                  return LineTooltipItem(
                    '$count\n',
                    TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            // ── Grid ──────────────────────────────────────────────────────
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval:
                  maxY > 4 ? (maxY / 3).ceilToDouble() : 1,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.grey.shade100,
                strokeWidth: 1,
              ),
            ),

            // ── Axes ──────────────────────────────────────────────────────
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= keys.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(
                        keys[idx],
                        style: TextStyle(
                            fontSize: 7.5, color: Colors.grey.shade400),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),

            borderData: FlBorderData(show: false),

            // ── Line ──────────────────────────────────────────────────────
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: lineColor,
                barWidth: 2.5,
                // No static dots — they appear only when touching
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      lineColor.withValues(alpha: 0.18),
                      lineColor.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
