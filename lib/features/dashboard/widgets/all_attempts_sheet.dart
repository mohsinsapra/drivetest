import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import '../helpers/dashboard_helpers.dart';

class AllAttemptsSheet extends StatelessWidget {
  const AllAttemptsSheet({
    super.key,
    required this.batchName,
    required this.attempts,
    required this.onResume,
  });

  final String batchName;
  final List<TestAttempt> attempts;
  final void Function(TestAttempt) onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat('d MMM y, HH:mm');
    final t = Translations.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, sc) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              batchName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: attempts.length,
                itemBuilder: (context, index) {
                  final a = attempts[index];
                  final isPaused = a.isPaused;
                  final isCompleted = a.isCompleted;
                  final dur = a.durationSeconds ?? 0;
                  final durLabel =
                      dur > 0 ? DashboardHelpers.formatDuration(dur) : '—';

                  final Color statusColor = isPaused
                      ? Colors.orange
                      : (a.hasPassed ? Colors.green : cs.error);
                  final IconData statusIcon = isPaused
                      ? Icons.pause_circle_filled_rounded
                      : (a.hasPassed
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded);
                  final String statusLabel = isPaused
                      ? t.home_resume
                      : (a.hasPassed ? t.home_passed : t.home_failed);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          if (isPaused) {
                            Navigator.pop(context);
                            onResume(a);
                          } else if (isCompleted && a.questions.isNotEmpty) {
                            Navigator.push(
                              context,
                              AppPageRoute(
                                builder: (_) => TestscreenWrapper(
                                  questions: a.questions,
                                  instantMarking: true,
                                  licenceId: a.licenceId ?? '',
                                  categoryId: a.categoryId ?? '',
                                  licenceName: a.licenceName ?? '',
                                  categoryName: a.categoryName ?? '',
                                  userSelections: a.userSelections,
                                  isReviewMode: true,
                                  bcdCategoryId: a.bcdCategoryId,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(statusIcon,
                                    color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fmt.format(a.dateTime),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      durLabel,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.5)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPaused
                                      ? statusLabel
                                      : '${a.score.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isCompleted && a.questions.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 16,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
