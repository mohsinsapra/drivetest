import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, this.stats});

  final ExamDashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);
    final progress = stats?.overallProgressPercent ?? 0;

    final String subtitle;
    if (progress == 0) {
      subtitle = t.dash_hero_sub_start;
    } else if (progress < 50) {
      subtitle = t.dash_hero_sub_progress;
    } else if (progress < 100) {
      subtitle = t.dash_hero_sub_almost;
    } else {
      subtitle = t.dash_hero_sub_done;
    }

    return SizedBox(
      height: 62,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.dash_my_progress,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.1,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
