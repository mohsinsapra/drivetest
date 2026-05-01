import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:flutter/material.dart';
import '../../features/tests/result_screen.dart';
import '../models/question.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// 1. Finish-confirmation dialog
/// ─────────────────────────────────────────────────────────────────────────────
Future<void> showFinishConfirmationDialog({
  required BuildContext context,
  required int unansweredCount,
  required VoidCallback onCancel,
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Finish Test'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(ctx).pop(), // close
          ),
        ],
      ),
      content: Text(
        unansweredCount > 0
            ? 'You have $unansweredCount unanswered question(s). '
                'Do you still want to finish the test?'
            : 'Do you want to finish the test?',
      ),
      actions: [
        TextButton(
          child: const Text('No'),
          onPressed: () {
            Navigator.of(ctx).pop(); // close
            onCancel();
          },
        ),
        ElevatedButton(
          child: const Text('Yes'),
          onPressed: () {
            Navigator.of(ctx).pop(); // close
            onConfirm();
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
  final Color primaryColor =
      hasPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  hasPassed ? 'Congratulations!' : 'Not Quite There',
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    hasPassed ? 'PASSED' : 'FAILED',
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
                  ? 'You have passed the test. Well done!'
                  : 'Keep practicing and try again. You can do it!',
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
                    child: const Text('Go Back'),
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
                    child: const Text('See Results'),
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
