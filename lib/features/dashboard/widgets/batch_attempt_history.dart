import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import '../helpers/dashboard_helpers.dart';
import '../models/dashboard_stats.dart';
import '../models/subscribed_exam.dart';
import 'all_attempts_sheet.dart';

class BatchAttemptHistory extends StatelessWidget {
  const BatchAttemptHistory({
    super.key,
    required this.batchAttempts,
    required this.exam,
    required this.batch,
    required this.onNewTest,
    required this.onResume,
  });

  final List<TestAttempt> batchAttempts;
  final SubscribedExam exam;
  final BatchStats batch;
  final VoidCallback? onNewTest;
  final void Function(TestAttempt) onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat('d MMM y');
    final t = Translations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                if (onNewTest != null) ...[
                  Expanded(
                    child: AppSecondaryButton(
                      label: t.dash_new_test,
                      onPressed: onNewTest,
                      height: 40,
                      fontSize: 14,
                    ),
                  ),
                  () {
                    final paused = batchAttempts
                        .where((a) => a.isPaused)
                        .toList()
                      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
                    if (paused.isEmpty) return const SizedBox.shrink();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () => onResume(paused.first),
                            icon: const Icon(Icons.play_circle_outline_rounded,
                                size: 16),
                            label: Text(t.home_resume),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              textStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    );
                  }(),
                ],
              ],
            ),
          ),
          if (batchAttempts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                t.dash_no_attempts_yet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.dash_previous_attempts,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (batchAttempts.length > 3)
                    TextButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AllAttemptsSheet(
                          batchName: batch.node.name,
                          attempts: batchAttempts,
                          onResume: onResume,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        t.dash_see_all,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ...() {
              final shown = batchAttempts.take(3).toList();
              return shown.map((a) {
                final isPaused = a.isPaused;
                final scoreColor = a.hasPassed ? Colors.green : cs.error;
                final dur = a.durationSeconds ?? 0;
                final durLabel =
                    dur > 0 ? DashboardHelpers.formatDuration(dur) : '—';

                return Column(
                  children: [
                    InkWell(
                      onTap: isPaused ? () => onResume(a) : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            Icon(
                              isPaused
                                  ? Icons.pause_circle_filled_rounded
                                  : (a.hasPassed
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded),
                              size: 18,
                              color: isPaused
                                  ? Colors.orange
                                  : (a.hasPassed ? Colors.green : cs.error),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fmt.format(a.dateTime),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    durLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPaused)
                              Text(
                                t.home_resume,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              Text(
                                '${a.score.toStringAsFixed(0)}%',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (a != shown.last)
                      Divider(
                        height: 1,
                        indent: 38,
                        color: cs.onSurface.withValues(alpha: 0.05),
                      ),
                  ],
                );
              });
            }(),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
