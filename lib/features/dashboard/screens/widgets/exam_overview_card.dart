import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../../models/subscribed_exam.dart';

class ExamOverviewCard extends StatelessWidget {
  const ExamOverviewCard({
    super.key,
    required this.exam,
    required this.progressPercent,
    required this.isSelected,
    required this.onTap,
    this.continueLabel,
  });

  final SubscribedExam exam;

  /// 0–100
  final double progressPercent;
  final bool isSelected;
  final VoidCallback onTap;

  /// e.g. "Continue: L2" — the next recommended batch name
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = (progressPercent / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withOpacity(0.12)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular progress
            Center(
              child: SizedBox(
                height: 64,
                width: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: cs.onSurface.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                    Center(
                      child: Text(
                        '${progressPercent.toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exam.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (continueLabel != null)
              Text(
                continueLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                progressPercent >= 100
                    ? Translations.of(context).dash_completed
                    : Translations.of(context).dash_tap_to_explore,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
