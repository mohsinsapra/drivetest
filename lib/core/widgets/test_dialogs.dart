import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../../features/tests/result_screen.dart';
import '../models/question.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// 1. Finish-confirmation dialog
/// ─────────────────────────────────────────────────────────────────────────────
Future<void> showFinishConfirmationDialog({
  required BuildContext context,
  required int unansweredCount,
  required FutureOr<void> Function() onCancel,
  required FutureOr<void> Function() onConfirm,
}) {
  final t = Translations.of(context);
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t.test_finish_title),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(ctx).pop(), // close
          ),
        ],
      ),
      content: Text(
        unansweredCount > 0
            ? t.test_finish_unanswered_prompt
                .replaceAll('{count}', '$unansweredCount')
            : t.test_finish_prompt,
      ),
      actions: [
        TextButton(
          child: Text(t.test_finish_no),
          onPressed: () async {
            Navigator.of(ctx).pop(); // close
            await onCancel();
          },
        ),
        ElevatedButton(
          child: Text(t.test_finish_yes),
          onPressed: () async {
            Navigator.of(ctx).pop(); // close
            await onConfirm();
          },
        ),
      ],
    ),
  );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 2. Result (pass/fail) dialog
/// ─────────────────────────────────────────────────────────────────────────────
Future<void> showResultDialog({
  required BuildContext context,
  required bool hasPassed,
  required List<Question> questions,
  required Map<int, String> userSelections,
  required String licenceId,
  required String categoryId,
  double score = 0,
  double passScorePercent = 70,
}) {
  final t = Translations.of(context);
  final Color primaryColor =
      hasPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colored header with icon and score
          Container(
            width: double.infinity,
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasPassed
                        ? Icons.emoji_events_rounded
                        : Icons.sentiment_dissatisfied_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hasPassed
                      ? t.test_result_congratulations
                      : t.test_result_not_quite_there,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${score.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    hasPassed
                        ? t.test_result_passed_badge
                        : t.test_result_failed_badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body message
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              hasPassed
                  ? t.test_result_pass_message
                  : t.test_result_fail_message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop(); // close dialog
                      Navigator.of(ctx).pop(); // pop TestScreen
                    },
                    child: Text(t.test_result_go_back),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.pushAndRemoveUntil(
                        ctx,
                        AppPageRoute(
                          builder: (_) => ResultScreen(
                            questions: questions,
                            userSelections: userSelections,
                            licenceId: licenceId,
                            categoryId: categoryId,
                            hasPassed: hasPassed,
                            passScorePercent: passScorePercent,
                          ),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    child: Text(t.test_result_see_results),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
