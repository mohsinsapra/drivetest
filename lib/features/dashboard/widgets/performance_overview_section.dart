import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import 'performance_insight_card.dart';
import 'performance_metric_card.dart';
import 'period_dropdown.dart';

class PerformanceOverviewSection extends StatelessWidget {
  const PerformanceOverviewSection({
    super.key,
    required this.stats,
    required this.provider,
  });

  final ExamDashboardStats stats;
  final DashboardProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    final avgSecs = stats.avgDurationSeconds;
    final avgMinutes = avgSecs ~/ 60;
    final avgTimeLabel = avgSecs == 0 ? '0m' : '${avgMinutes}m';
    final batchProgress = stats.totalBatchCount > 0
        ? stats.completedBatchCount / stats.totalBatchCount
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '${t.dash_perf_title1}\n',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            height: 1.15,
                          ),
                        ),
                        TextSpan(
                          text: t.dash_perf_title2,
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            height: 1.15,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.dash_perf_subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PeriodDropdown(
                period: provider.period,
                onChanged: provider.setPeriod,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              const minCardW = 100.0;
              final fits3 = constraints.maxWidth >= minCardW * 3 + gap * 2;

              final cards = [
                PerformanceMetricCard(
                  color: cs.primary,
                  bgColor: cs.primary.withValues(alpha: 0.06),
                  icon: Icons.history_rounded,
                  progress: stats.totalAttempts > 0 ? 0.65 : 0.0,
                  value: '${stats.totalAttempts}',
                  numericValue: stats.totalAttempts.toDouble(),
                  title: t.dash_total_attempts,
                  chip: stats.totalAttempts == 0
                      ? t.dash_stat_none_yet
                      : t.dash_stat_completed,
                  chipColor: stats.totalAttempts > 0
                      ? const Color(0xFF4CAF50)
                      : null,
                  chipDot: stats.totalAttempts > 0,
                  description: t.dash_perf_attempts_desc,
                  isCompact: true,
                ),
                PerformanceMetricCard(
                  color: cs.secondary,
                  bgColor: cs.secondary.withValues(alpha: 0.06),
                  icon: Icons.layers_rounded,
                  progress: batchProgress,
                  value: '${stats.completedBatchCount}',
                  numericValue: stats.completedBatchCount.toDouble(),
                  title: t.dash_batches_done,
                  chip: t.dash_stat_of_n
                      .replaceAll('{total}', '${stats.totalBatchCount}'),
                  chipColor: null,
                  chipDot: false,
                  description: t.dash_perf_batches_desc,
                  isCompact: true,
                ),
                PerformanceMetricCard(
                  color: cs.tertiary,
                  bgColor: cs.tertiary.withValues(alpha: 0.06),
                  icon: Icons.timer_rounded,
                  progress: avgSecs > 0 ? 0.4 : 0.0,
                  value: avgTimeLabel,
                  title: t.dash_avg_time_per_session,
                  chip: t.dash_stat_per_session,
                  chipColor: cs.tertiary,
                  chipDot: false,
                  description: t.dash_perf_time_desc,
                  isCompact: true,
                ),
              ];

              if (fits3) {
                return Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }

              final cardW = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: cards
                    .map((c) => SizedBox(width: cardW, child: c))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          const PerformanceInsightCard(),
        ],
      ),
    );
  }
}
