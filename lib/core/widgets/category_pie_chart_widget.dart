import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatefulWidget {
  final Map<String, int> data;
  final String title;

  const CategoryPieChart({
    Key? key,
    required this.data,
    this.title = "Categories",
  }) : super(key: key);

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touched = -1;

  static const _colors = [
    Color(0xFF4F8FFF), // Soft Blue
    Color(0xFF43D9B8), // Mint Green
    Color(0xFFFFB86C), // Peach Orange
    Color(0xFFB388FF), // Lavender Purple
    Color(0xFF6EE7B7), // Light Teal
    Color(0xFFFF6F91), // Coral Pink
  ];

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final total = data.values.fold(0, (sum, value) => sum + value);
    final keys = data.keys.toList();
    final vals = data.values.toList();

    final sections = List.generate(keys.length, (i) {
      final pct = total > 0 ? vals[i] / total * 100 : 0.0;
      final isSelected = _touched == i;
      return PieChartSectionData(
        color: _colors[i % _colors.length],
        value: vals[i].toDouble(),
        radius: isSelected ? 72 : 55,
        // Show % inside slice only when selected or when slice is large enough
        title: isSelected
            ? '${pct.toStringAsFixed(0)}%'
            : (pct >= 14 ? '${pct.toStringAsFixed(0)}%' : ''),
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
        ),
        titlePositionPercentageOffset: 0.65,
      );
    });

    // Center overlay content
    final String centerTop;
    final String centerBottom;
    final Color centerColor;
    if (_touched >= 0 && _touched < keys.length) {
      final pct = total > 0 ? vals[_touched] / total * 100 : 0.0;
      centerTop = keys[_touched];
      centerBottom = '${pct.toStringAsFixed(1)}%';
      centerColor = _colors[_touched % _colors.length];
    } else {
      centerTop = '$total';
      centerBottom = 'total';
      centerColor = Colors.grey.shade700;
    }

    return Card(
      color: const Color.fromARGB(255, 246, 246, 248),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Tap a slice to see details',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 44,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          // Only act on tap-up to avoid rapid toggle from move events
                          if (event is! FlTapUpEvent) return;
                          setState(() {
                            if (response?.touchedSection == null) {
                              _touched = -1;
                              return;
                            }
                            final idx = response!
                                .touchedSection!.touchedSectionIndex;
                            _touched = _touched == idx ? -1 : idx;
                          });
                        },
                      ),
                    ),
                  ),
                  // Center text overlay — no keys, avoids AnimatedSwitcher duplicate-key crash
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontSize: _touched >= 0 ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: centerColor,
                        ),
                        child: Text(
                          centerBottom,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        centerTop,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: keys.asMap().entries.map((e) {
                final i = e.key;
                final key = e.value;
                final color = _colors[i % _colors.length];
                final pct = total > 0 ? vals[i] / total * 100 : 0.0;
                final isSelected = _touched == i;
                return GestureDetector(
                  onTap: () => setState(
                      () => _touched = _touched == i ? -1 : i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(width: 5),
                        Text(key,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                        const SizedBox(width: 4),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? color
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
