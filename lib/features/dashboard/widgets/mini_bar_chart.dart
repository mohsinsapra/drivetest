import 'package:flutter/material.dart';

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const heights = [0.3, 0.5, 0.65, 0.8, 1.0];
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
              height: maxH * heights[i],
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
