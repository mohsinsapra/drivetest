import 'package:flutter/material.dart';

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.color,
    this.heights = const [0.3, 0.5, 0.65, 0.8, 1.0],
  });

  final Color color;

  /// Normalized bar heights in [0.0, 1.0], oldest → newest (left → right).
  final List<double> heights;

  @override
  Widget build(BuildContext context) {
    const maxH = 40.0;
    const barW = 7.0;

    return SizedBox(
      height: maxH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: barW,
              height: maxH * heights[i].clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
