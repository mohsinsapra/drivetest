import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../../helpers/dashboard_helpers.dart';
import '../../models/dashboard_stats.dart';

class BatchProgressCard extends StatelessWidget {
  const BatchProgressCard({
    super.key,
    required this.stats,
    this.categoryName,
    this.onTap,
    /// When true, renders as a flat row inside a parent section container
    /// (no individual card border or outer margin).
    this.nested = false,
  });

  final BatchStats stats;

  /// Shown as context label (only used in 3-layer view)
  final String? categoryName;
  final VoidCallback? onTap;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = (stats.progressPercent / 100).clamp(0.0, 1.0);
    final isUntouched = stats.isUntouched;

    Color statusColor = _statusColor(stats.weaknessType, stats.isCompleted, cs);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: nested
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: nested
            ? null
            : BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: stats.isCompleted
                      ? Colors.green.withOpacity(0.25)
                      : cs.onSurface.withOpacity(0.07),
                ),
              ),
        child: Column(
          children: [
            Row(
              children: [
                // Status indicator dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),

                // Name + category context
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.node.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (categoryName != null)
                        Text(
                          categoryName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.45),
                          ),
                        ),
                    ],
                  ),
                ),

                // Score / status on right
                if (isUntouched)
                  Text(
                    Translations.of(context).dash_not_started,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  )
                else
                  Text(
                    '${stats.averageScore.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
              ],
            ),

            if (!isUntouched) ...[
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: cs.onSurface.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    stats.isCompleted ? Colors.green : cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Attempts + time row
              Builder(builder: (context) {
                final t = Translations.of(context);
                final attemptsLabel = stats.attempts == 1
                    ? t.dash_attempt_one
                    : t.dash_attempt_many.replaceAll('{n}', '${stats.attempts}');
                return Row(
                children: [
                  _MiniStat(
                    icon: Icons.repeat_rounded,
                    label: attemptsLabel,
                  ),
                  const SizedBox(width: 14),
                  _MiniStat(
                    icon: Icons.timer_outlined,
                    label: t.dash_avg_duration.replaceAll(
                        '{duration}', DashboardHelpers.formatDuration(stats.avgDurationSeconds)),
                  ),
                  if (stats.targetDurationSeconds > 0) ...[
                    const SizedBox(width: 14),
                    _TimeEfficiencyBadge(stats: stats),
                  ],
                ],
              );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(
      WeaknessType type, bool isCompleted, ColorScheme cs) {
    if (isCompleted) return Colors.green;
    switch (type) {
      case WeaknessType.lowScore:
        return Colors.orange;
      case WeaknessType.overTime:
        return Colors.blue.shade300;
      case WeaknessType.both:
        return Colors.redAccent;
      case WeaknessType.none:
        return cs.primary;
    }
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurface.withOpacity(0.45)),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: cs.onSurface.withOpacity(0.55)),
        ),
      ],
    );
  }
}

class _TimeEfficiencyBadge extends StatelessWidget {
  const _TimeEfficiencyBadge({required this.stats});
  final BatchStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = stats.timeEfficiencyRatio;
    final isOver = stats.isOverTime;
    final color = isOver ? Colors.orange : Colors.green;
    final t = Translations.of(context);
    final label = isOver
        ? t.dash_over_time_pct.replaceAll('{pct}', ((ratio - 1) * 100).toStringAsFixed(0))
        : t.dash_on_time;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
