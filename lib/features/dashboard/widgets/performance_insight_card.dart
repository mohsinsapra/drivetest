import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';

class PerformanceInsightCard extends StatelessWidget {
  const PerformanceInsightCard({
    super.key,
    required this.stats,
    this.isLoading = false,
  });

  final ExamDashboardStats stats;
  final bool isLoading;

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.6),
                height: 1.3,
              ),
            ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.layers_rounded,
              label: '$completed / $total',
              color: cs.secondary,
            ),
            if (avgScore > 0) ...[
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.percent_rounded,
                label: avgScore.toStringAsFixed(0),
                color: avgScore >= 70 ? cs.primary : cs.error,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? cs.surfaceContainerHighest
            : cs.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
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
