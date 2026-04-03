import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_exam_app/core/router/route_args.dart';
import 'package:taxi_exam_app/core/router/route_names.dart';
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
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hasPassed ? 'Congratulations!' : 'Test Completed'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(ctx).pop(), // close
          ),
        ],
      ),
      content: Text(hasPassed
          ? 'You have passed the test.'
          : 'You did not pass the test.'),
      actions: [
        TextButton(
          child: const Text('Go Back to Tests'),
          onPressed: () {
            Navigator.of(ctx).pop();       // close
            Navigator.of(ctx).pop();       // pop Testscreen
          },
        ),
        ElevatedButton(
          child: const Text('See Results'),
          onPressed: () {
            Navigator.of(ctx).pop(); // close
            ctx.pushReplacement(Routes.result, extra: ResultScreenArgs(
              questions: questions,
              userSelections: userSelections,
              licenceId: licenceId,
              categoryId: categoryId,
              hasPassed: hasPassed,
            ));
          },
        ),
      ],
    ),
  );
}
