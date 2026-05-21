import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'mini_bar_chart.dart';

class PerformanceInsightCard extends StatelessWidget {
  const PerformanceInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.star_rounded, size: 28, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.dash_keep_it_up,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  t.dash_consistency_today,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MiniBarChart(color: cs.primary.withValues(alpha: 0.25)),
        ],
      ),
    );
  }
}
