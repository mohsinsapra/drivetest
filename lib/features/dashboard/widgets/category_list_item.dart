import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';
import 'batch_row.dart';
import 'exam_nav_helpers.dart';

class CategoryListItem extends StatefulWidget {
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
  State<CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<CategoryListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curved;
  // Deferred build: content is only constructed after the first expansion.
  late bool _hasBeenExpanded;

  @override
  void initState() {
    super.initState();
    _hasBeenExpanded = widget.isExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(CategoryListItem old) {
    super.didUpdateWidget(old);
    if (old.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _hasBeenExpanded = true;
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final t = Translations.of(context);

    final statusText = widget.cat.touchedBatches == 0
        ? t.dash_not_started
        : t.dash_avg_score_label.replaceAll(
            '{score}',
            widget.cat.averageScore.toStringAsFixed(0),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: widget.isExpanded ? cs.surfaceContainerLow : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isExpanded
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
                onTap: widget.onToggle,
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
                          color: widget.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cat.node.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${t.dash_batches_count.replaceAll('{n}', '${widget.cat.totalBatches}')} • $statusText',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: widget.isExpanded ? 0.25 : 0.0,
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
              child: AnimatedBuilder(
                animation: _curved,
                builder: (ctx, child) {
                  // Dispose children entirely when fully collapsed — no build cost.
                  if (_ctrl.status == AnimationStatus.dismissed) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _curved.value,
                    child: child,
                  );
                },
                child: _hasBeenExpanded
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: cs.onSurface.withValues(alpha: 0.07),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: widget.cat.batchStats
                              .asMap()
                              .entries
                              .map((e) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: e.key <
                                              widget.cat.batchStats.length - 1
                                          ? 8
                                          : 0,
                                    ),
                                    child: BatchRow(
                                      batch: e.value,
                                      exam: widget.stats.exam,
                                      nested: true,
                                      batchAttempts: e.value.sortedAttempts,
                                      onTap: widget.stats.exam.isBcd
                                          ? () => launchBatch(
                                                context,
                                                widget.stats.exam,
                                                e.value.node,
                                                widget.cat.node.name,
                                              )
                                          : null,
                                    ),
                                  ))
                              .toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
