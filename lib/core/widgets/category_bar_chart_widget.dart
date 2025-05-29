import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryBarChart extends StatelessWidget {
  final Map<String, int> data;

  const CategoryBarChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = data.keys.toList();
    final values = data.values.toList();
    final maxY = values.isEmpty
        ? 1
        : (values.reduce((a, b) => a > b ? a : b).toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Attempts by Category",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + 1,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, _) {
                      if (value.toInt() < categories.length) {
                        return SideTitleWidget(
                          space: 4,
                          meta: _,
                          child: Text(categories[value.toInt()],
                              style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(categories.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: values[index].toDouble(),
                      color: Theme.of(context).colorScheme.primary,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
