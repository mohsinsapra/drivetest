import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../../models/dashboard_stats.dart';

class CategoryProgressCard extends StatelessWidget {
  const CategoryProgressCard({
    super.key,
    required this.stats,
    this.onTap,

    /// When true the widget renders without its own outer card decoration
    /// (used when placed inside a collapsible section container).
    this.nested = false,

    /// Shows a rotating chevron to indicate expand/collapse state.
    this.showChevron = false,
    this.isExpanded = false,
  });

  final CategoryStats stats;
  final VoidCallback? onTap;
  final bool nested;
  final bool showChevron;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = (stats.progressPercent / 100).clamp(0.0, 1.0);

    Color weaknessColor = _weaknessColor(stats.dominantWeakness, cs);

    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Left: name + batch count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.node.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Translations.of(context)
                          .dash_batches_completed_label
                          .replaceAll('{done}', '${stats.completedBatches}')
                          .replaceAll('{total}', '${stats.totalBatches}'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Right: score + weakness + optional chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats.averageScore.toStringAsFixed(0)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                      if (stats.dominantWeakness != WeaknessType.none)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: _WeaknessChip(
                            type: stats.dominantWeakness,
                            color: weaknessColor,
                          ),
                        ),
                    ],
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: cs.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : cs.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (nested) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: content,
      ),
    );
  }

  Color _weaknessColor(WeaknessType t, ColorScheme cs) {
    switch (t) {
      case WeaknessType.lowScore:
        return Colors.orange;
      case WeaknessType.overTime:
        return Colors.blue.shade300;
      case WeaknessType.both:
        return Colors.redAccent;
      case WeaknessType.none:
        return Colors.green;
    }
  }
}

class _WeaknessChip extends StatelessWidget {
  const _WeaknessChip({required this.type, required this.color});
  final WeaknessType type;
  final Color color;

  String _label(Translations t) {
    switch (type) {
      case WeaknessType.lowScore:
        return t.dash_weakness_low_score;
      case WeaknessType.overTime:
        return t.dash_weakness_over_time;
      case WeaknessType.both:
        return t.dash_weakness_needs_work;
      case WeaknessType.none:
        return t.dash_weakness_on_track;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(Translations.of(context)),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
