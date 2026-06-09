import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import '../models/dashboard_stats.dart';
import '../models/subscribed_exam.dart';
import 'batch_attempt_history.dart';
import 'exam_nav_helpers.dart';

class BatchRow extends StatefulWidget {
  const BatchRow({
    super.key,
    required this.batch,
    required this.exam,
    required this.batchAttempts,
    this.onTap,
    this.nested = false,
  });

  final BatchStats batch;
  final SubscribedExam exam;
  final List<TestAttempt> batchAttempts;
  final Future<void> Function()? onTap;
  final bool nested;

  @override
  State<BatchRow> createState() => _BatchRowState();
}

class _BatchRowState extends State<BatchRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curved;
  bool _expanded = false;
  // Deferred build: attempt history is only constructed after first expansion.
  bool _hasBeenExpanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) _hasBeenExpanded = true;
    });
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final batch = widget.batch;

    Color dotColor;
    if (batch.isCompleted) {
      dotColor = Colors.green;
    } else if (batch.isLowScore) {
      dotColor = Colors.orange;
    } else if (batch.isUntouched) {
      dotColor = cs.onSurface.withValues(alpha: 0.2);
    } else {
      dotColor = cs.primary;
    }

    final batchAttempts = widget.batchAttempts;
    final hasPaused = batchAttempts.any((a) => a.isPaused);
    final isNested = widget.nested;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: isNested
          ? BoxDecoration(
              color: _expanded ? cs.surfaceContainerLowest : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            )
          : BoxDecoration(
              color: _expanded ? cs.surfaceContainerLow : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _expanded
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
        borderRadius: BorderRadius.circular(isNested ? 12 : 16),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _toggle,
                splashColor: cs.primary.withValues(alpha: 0.08),
                highlightColor: cs.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatNodeName(batch.node.name,
                                  Translations.of(context).node_group_prefix),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            if (!batch.isUntouched)
                              Text(
                                '${batchAttempts.length == 1 ? Translations.of(context).dash_attempt_one : Translations.of(context).dash_attempt_many.replaceAll('{n}', '${batchAttempts.length}')} · ${batch.averageScore.toStringAsFixed(0)}% avg',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (hasPaused)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.pause_circle_outline_rounded,
                            size: 13,
                            color: Colors.orange,
                          ),
                        ),
                      if (!batch.isUntouched)
                        Text(
                          '${batch.averageScore.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: dotColor,
                          ),
                        ),
                      const SizedBox(width: 2),
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: cs.onSurface.withValues(alpha: 0.3),
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
                  return Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _curved.value,
                    child: child,
                  );
                },
                child: _hasBeenExpanded
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          border: Border(
                            top: BorderSide(
                              color: cs.onSurface.withValues(alpha: 0.07),
                            ),
                          ),
                        ),
                        child: BatchAttemptHistory(
                          batchAttempts: batchAttempts,
                          exam: widget.exam,
                          batch: batch,
                          onNewTest: widget.onTap,
                          onResume: (attempt) => resumeAttempt(
                              context, attempt, widget.exam, batch),
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
