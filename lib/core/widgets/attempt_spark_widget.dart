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
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    final values = data.values.toList();

    final spots = List.generate(
        values.length, (i) => FlSpot(i.toDouble(), values[i].toDouble()));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            minY: 0,
            lineTouchData: LineTouchData(enabled: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              // bottomTitles: AxisTitles(
              //   sideTitles: SideTitles(
              //     showTitles: true,
              //     interval: 1,
              //     getTitlesWidget: (value, meta) {
              //       final index = value.toInt();
              //       if (index >= 0 && index < labels.length) {
              //         return SideTitleWidget(
              //           meta: meta,
              //           space: 6,
              //           child: Text(
              //             labels[index],
              //             style: const TextStyle(fontSize: 10),
              //           ),
              //         );
              //       }
              //       return const SizedBox.shrink();
              //     },
              //   ),
              // ),
              bottomTitles: AxisTitles(
                sideTitles:
                    SideTitles(showTitles: false), // ← hide bottom X labels
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: lineColor,
                barWidth: 2.5,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              )
            ],
          ),
        ),
      ),
    );
  }
}
