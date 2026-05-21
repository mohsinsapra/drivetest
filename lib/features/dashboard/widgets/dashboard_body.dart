import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';
import '../providers/dashboard_provider.dart';
import 'exam_carousel_section.dart';
import 'focus_categories_section.dart';
import 'hero_section.dart';
import 'performance_overview_section.dart';
import 'weekly_streak_section.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.provider,
    required this.onSubscribe,
    required this.onRefresh,
  });

  final DashboardProvider provider;
  final VoidCallback onSubscribe;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final stats = provider.selectedStats;
    final t = Translations.of(context);

    return AdaptiveRefreshIndicator(
      onRefresh: onRefresh,
      slivers: [
        SliverToBoxAdapter(child: HeroSection(stats: stats)),

        SliverToBoxAdapter(
          child: ExamCarouselSection(
            provider: provider,
            onSubscribe: onSubscribe,
          ),
        ),

        if (stats != null)
          SliverToBoxAdapter(
            child: PerformanceOverviewSection(
              stats: stats,
              provider: provider,
            ),
          ),

        if (stats != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Text(
                t.dash_focus_areas,
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FocusCategoriesSection(stats: stats),
          ),
        ],

        if (stats != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: Text(
                t.dash_weekly_streak,
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: WeeklyStreakSection(streak: stats.streak),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}
