import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';
import 'mini_bar_chart.dart';

class PerformanceInsightCard extends StatelessWidget {
  const PerformanceInsightCard({
    super.key,
    required this.stats,
    this.isLoading = false,
  });

  final ExamDashboardStats stats;
  final bool isLoading;

  /// Normalized bar heights representing the last 5 days of streak activity.
  /// Full bar (1.0) = active day, dim stub (0.08) = no activity.
  List<double> _streakBars() {
    final streak = stats.streak.currentStreak.clamp(0, 5);
    return List.generate(5, (i) => i >= (5 - streak) ? 1.0 : 0.08);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildShimmer(context);
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    final streak = stats.streak.currentStreak;
    final avgScore = stats.overallAverageScore;
    final completed = stats.completedBatchCount;
    final total = stats.totalBatchCount;

    final subtitle = streak > 0
        ? t.dash_streak_msg_amazing.replaceAll('{n}', '$streak')
        : t.dash_consistency_today;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      subtitle,
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
              MiniBarChart(
                color: cs.primary.withValues(alpha: 0.6),
                heights: _streakBars(),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: cs.onSurface.withValues(alpha: 0.07),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  icon: Icons.layers_rounded,
                  label: '$completed / $total',
                  color: cs.secondary,
                ),
                const SizedBox(width: 12),
                if (avgScore > 0)
                  _StatChip(
                    icon: Icons.percent_rounded,
                    label: t.dash_avg_score_label
                        .replaceAll('{score}', avgScore.toStringAsFixed(0)),
                    color: avgScore >= 70 ? cs.primary : cs.error,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: isDark
          ? cs.onSurface.withValues(alpha: 0.12)
          : cs.onSurface.withValues(alpha: 0.08),
      highlightColor: isDark
          ? cs.onSurface.withValues(alpha: 0.06)
          : cs.onSurface.withValues(alpha: 0.03),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 96,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 124,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(5, (i) {
                    final heights = [14.0, 20.0, 28.0, 36.0, 28.0];
                    return Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
                      child: Container(
                        width: 6,
                        height: heights[i],
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: cs.onSurface.withValues(alpha: 0.07),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildChipShimmer(width: 74),
                const SizedBox(width: 12),
                _buildChipShimmer(width: 92),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipShimmer({required double width}) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
