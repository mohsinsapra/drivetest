import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, int> data;
  final String title;

  const CategoryPieChart({
    Key? key,
    required this.data,
    this.title = "Categories",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (sum, value) => sum + value);
    final colors = [
      const Color(0xFF4F8FFF), // Soft Blue
      const Color(0xFF43D9B8), // Mint Green
      const Color(0xFFFFB86C), // Peach Orange
      const Color(0xFFB388FF), // Lavender Purple
      const Color(0xFF6EE7B7), // Light Teal
      const Color(0xFFFF6F91), // Coral Pink
    ];

    final sections = <PieChartSectionData>[];
    int i = 0;

    data.forEach((label, value) {
      final percent = (value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: value.toDouble(),
          title:
              "${label.length > 8 ? label.substring(0, 8) + '...' : label}\n${percent.toStringAsFixed(1)}%",
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          radius: 60,
          titlePositionPercentageOffset: 0.6,
        ),
      );
      i++;
    });

    return Card(
      color: const Color.fromARGB(255, 246, 246, 248), // very light blue
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 32,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.keys.map((label) {
                final color =
                    colors[data.keys.toList().indexOf(label) % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 6),
                    Text(label, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
