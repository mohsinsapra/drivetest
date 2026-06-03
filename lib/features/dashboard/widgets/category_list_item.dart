import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/features/bcd/bcd_text_utils.dart';
import '../models/dashboard_stats.dart';
import 'batch_row.dart';
import 'exam_nav_helpers.dart';

class CategoryListItem extends StatefulWidget {
  const CategoryListItem({
    super.key,
    required this.cat,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.stats,
    this.showRecentPill = false,
    this.nested = false,
  });

  final CategoryStats cat;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ExamDashboardStats stats;
  final bool showRecentPill;

  /// When true, renders without its own card decoration (for use inside a grouped container).
  final bool nested;

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

  Widget _buildInner(BuildContext context, ColorScheme cs, ThemeData theme,
      Translations t, String statusText) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          color: Colors.transparent,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              splashColor: cs.primary.withValues(alpha: 0.08),
              highlightColor: cs.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: cs.primary, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  formatNodeName(
                                      stripAppSuffix(widget.cat.node.name), t.node_group_prefix),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (widget.showRecentPill) ...[
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    t.dash_recently_practiced,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
        ),
        ClipRect(
          child: AnimatedBuilder(
            animation: _curved,
            builder: (ctx, child) {
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
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: widget.cat.batchStats.asMap().entries.map((e) {
                        final isLast =
                            e.key == widget.cat.batchStats.length - 1;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BatchRow(
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
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: cs.onSurface.withValues(alpha: 0.07),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statusText = widget.cat.touchedBatches == 0
        ? t.dash_not_started
        : t.dash_avg_score_label.replaceAll(
            '{score}',
            widget.cat.averageScore.toStringAsFixed(0),
          );

    if (widget.nested) return _buildInner(context, cs, theme, t, statusText);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
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
        child: _buildInner(context, cs, theme, t, statusText),
      ),
    );
  }
}
