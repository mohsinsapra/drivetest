import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import 'performance_insight_card.dart';
import 'period_dropdown.dart';

class PerformanceOverviewSection extends StatelessWidget {
  const PerformanceOverviewSection({
    super.key,
    required this.stats,
    required this.provider,
    this.isLoading = false,
  });

  final ExamDashboardStats stats;
  final DashboardProvider provider;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${t.dash_perf_title1} ',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: t.dash_perf_title2,
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        height: 1.2,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              PeriodDropdown(
                period: provider.period,
                onChanged: provider.setPeriod,
              ),
            ],
          ),
          const SizedBox(height: 12),
          isLoading
              ? _StatsRowShimmer()
              : _StatsRow(
                  key: ValueKey(stats.exam.id),
                  stats: [
                    _StatData(
                      color: cs.primary,
                      value: '${stats.totalAttempts}',
                      numericValue: stats.totalAttempts.toDouble(),
                      label: t.dash_total_attempts,
                      sub: stats.totalAttempts == 0
                          ? t.dash_stat_none_yet
                          : t.dash_stat_completed,
                    ),
                    _StatData(
                      color: cs.secondary,
                      value: '${stats.smartChunksMastered}',
                      numericValue: stats.smartChunksMastered.toDouble(),
                      label: t.dash_chunks_mastered,
                      sub: stats.smartChunksTotal == 0
                          ? t.dash_stat_none_yet
                          : t.dash_stat_of_n.replaceAll(
                              '{total}', '${stats.smartChunksTotal}'),
                    ),
                    _StatData(
                      color: cs.tertiary,
                      value: '${stats.weakQuestionsCount}',
                      numericValue: stats.weakQuestionsCount.toDouble(),
                      label: t.dash_weak_questions,
                      sub: stats.weakQuestionsCount == 0
                          ? t.dash_stat_none_yet
                          : t.dash_stat_to_train,
                    ),
                  ],
                ),
          const SizedBox(height: 10),
          PerformanceInsightCard(stats: stats, isLoading: isLoading),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _StatData {
  final Color color;
  final String value;
  final double? numericValue;
  final String label;
  final String sub;

  const _StatData({
    required this.color,
    required this.value,
    required this.label,
    required this.sub,
    this.numericValue,
  });
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({super.key, required this.stats});

  final List<_StatData> stats;

  static const _dur = Duration(milliseconds: 700);
  static const _curve = Interval(0.1, 1.0, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            Expanded(
                child: _StatCell(data: stats[i], dur: _dur, curve: _curve)),
            if (i < stats.length - 1)
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 12),
                color: cs.onSurface.withValues(alpha: 0.07),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.data,
    required this.dur,
    required this.curve,
  });

  final _StatData data;
  final Duration dur;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget valueWidget;
    if (data.numericValue != null) {
      valueWidget = TweenAnimationBuilder<double>(
        key: ValueKey('sv_${data.label}_${data.numericValue}'),
        tween: Tween(begin: 0.0, end: data.numericValue),
        duration: dur,
        curve: curve,
        builder: (_, v, __) => Text(
          '${v.round()}',
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: data.color,
            height: 1.0,
          ),
        ),
      );
    } else {
      valueWidget = Text(
        data.value,
        style: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: data.color,
          height: 1.0,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              valueWidget,
              if (data.sub.isNotEmpty) ...[
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '/ ${data.sub}',
                    style: GoogleFonts.lexend(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: GoogleFonts.lexend(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _StatsRowShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? cs.surfaceContainerHighest
            : cs.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
