import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';

class AttemptTimelineGraph extends StatelessWidget {
  final List<TestAttempt> attempts;
  final double height;
  final Color lineColor;

  const AttemptTimelineGraph({
    super.key,
    required this.attempts,
    this.height = 60,
    this.lineColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return const SizedBox(); // No graph if no data
    }

    final sorted = [...attempts]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final spots = List.generate(
      sorted.length,
      (i) => FlSpot(i.toDouble(), sorted[i].score),
    );

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: LineTouchData(enabled: false),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
