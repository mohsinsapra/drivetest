import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../../helpers/dashboard_helpers.dart';
import '../../models/dashboard_stats.dart';

class SelectedExamSummaryCard extends StatelessWidget {
  const SelectedExamSummaryCard({
    super.key,
    required this.stats,
    this.onContinueTap,
  });

  final ExamDashboardStats stats;
  final VoidCallback? onContinueTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  stats.exam.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _ProgressPill(percent: stats.overallProgressPercent),
            ],
          ),
          const SizedBox(height: 14),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (stats.overallProgressPercent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: cs.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 14),

          // Stat grid
          Builder(builder: (context) {
            final t = Translations.of(context);
            return Row(
              children: [
                _StatCell(
                  label: t.dash_total_attempts,
                  value: '${stats.totalAttempts}',
                  icon: Icons.repeat_rounded,
                ),
                _StatCell(
                  label: t.dash_batches_done,
                  value:
                      '${stats.completedBatchCount}/${stats.totalBatchCount}',
                  icon: Icons.check_circle_outline_rounded,
                ),
                _StatCell(
                  label: t.dash_avg_time,
                  value:
                      DashboardHelpers.formatDuration(stats.avgDurationSeconds),
                  icon: Icons.timer_outlined,
                ),
              ],
            );
          }),
          const SizedBox(height: 12),

          // Continue / weak area
          if (stats.continueNode != null)
            _ContinueBanner(
              batchName: stats.continueNode!.node.name,
              onTap: onContinueTap,
            ),

          if (stats.weakestBatch != null && stats.totalAttempts > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _WeakAreaChip(
                batchName: stats.weakestBatch!.node.name,
                score: stats.weakestBatch!.averageScore,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${percent.toStringAsFixed(0)}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContinueBanner extends StatelessWidget {
  const _ContinueBanner({required this.batchName, this.onTap});
  final String batchName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.play_arrow_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                Translations.of(context)
                    .dash_continue_label
                    .replaceAll('{name}', batchName),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _WeakAreaChip extends StatelessWidget {
  const _WeakAreaChip({required this.batchName, required this.score});
  final String batchName;
  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.warning_amber_rounded,
            size: 14, color: Colors.orange.shade400),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            Translations.of(context)
                .dash_weakest_label
                .replaceAll('{name}', batchName)
                .replaceAll('{score}', score.toStringAsFixed(0)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
