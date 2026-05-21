import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';
import 'batch_row.dart';
import 'exam_nav_helpers.dart';

class CategoryListItem extends StatelessWidget {
  const CategoryListItem({
    super.key,
    required this.cat,
    required this.icon,
    required this.color,
    required this.isExpanded,
    required this.onToggle,
    required this.stats,
  });

  final CategoryStats cat;
  final IconData icon;
  final Color color;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ExamDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final t = Translations.of(context);

    final statusText = cat.touchedBatches == 0
        ? t.dash_not_started
        : t.dash_avg_score_label.replaceAll(
            '{score}',
            cat.averageScore.toStringAsFixed(0),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: isExpanded ? cs.surfaceContainerLow : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? cs.primary.withValues(alpha: 0.15)
              : cs.onSurface.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onToggle,
                splashColor: cs.primary.withValues(alpha: 0.08),
                highlightColor: cs.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.node.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${t.dash_batches_count.replaceAll('{n}', '${cat.totalBatches}')} • $statusText',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                heightFactor: isExpanded ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: cs.onSurface.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: cat.batchStats
                        .asMap()
                        .entries
                        .map((e) => Padding(
                              padding: EdgeInsets.only(
                                bottom: e.key < cat.batchStats.length - 1
                                    ? 8
                                    : 0,
                              ),
                              // Use precomputed sortedAttempts — no build-time filtering.
                              child: BatchRow(
                                batch: e.value,
                                exam: stats.exam,
                                nested: true,
                                batchAttempts: e.value.sortedAttempts,
                                onTap: stats.exam.isBcd
                                    ? () => launchBatch(
                                          context,
                                          stats.exam,
                                          e.value.node,
                                          cat.node.name,
                                        )
                                    : null,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
