import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/bcd/bcd_test_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import '../helpers/dashboard_helpers.dart';
import '../models/dashboard_stats.dart';
import '../models/exam_node.dart';
import '../models/subscribed_exam.dart';
import '../providers/dashboard_provider.dart';

void launchBatch(
  BuildContext context,
  SubscribedExam exam,
  ExamNode batchNode,
  String? categoryName,
) {
  if (!exam.isBcd) return;

  final parentBcdId = int.tryParse(batchNode.parentId ?? exam.id) ?? 0;
  final parentName = categoryName ?? exam.name;

  Navigator.push(
    context,
    AppPageRoute(
      builder: (_) => BCDTestScreen(
        testId: int.tryParse(batchNode.id) ?? 0,
        testName: batchNode.name,
        passScore: batchNode.passScore,
        timeLimit: batchNode.targetDurationSeconds ~/ 60,
        parentCategoryName: parentName,
        parentCategoryBcdId: parentBcdId,
      ),
    ),
  ).then((_) {
    if (context.mounted) context.read<DashboardProvider>().refresh();
  });
}

void resumeAttempt(
  BuildContext context,
  dynamic attempt,
  SubscribedExam exam,
  BatchStats batch,
) {
  if (attempt.questions.isNotEmpty) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => TestscreenWrapper(
          questions: attempt.questions,
          instantMarking: true,
          licenceId: attempt.licenceId ?? '',
          categoryId: attempt.categoryId ?? '',
          licenceName: attempt.licenceName ?? '',
          categoryName: attempt.categoryName ?? '',
          initialQuestionIndex: attempt.currentQuestionIndex,
          userSelections: attempt.userSelections,
          resumeTestId: attempt.testId,
          bcdCategoryId: attempt.bcdCategoryId,
        ),
      ),
    ).then((_) {
      if (context.mounted) context.read<DashboardProvider>().refresh();
    });
  } else {
    launchBatch(context, exam, batch.node, null);
  }
}

void handleExamArrowTap(
  BuildContext context,
  SubscribedExam exam,
  DashboardProvider provider,
) {
  final paused = DashboardHelpers.latestPausedAttemptForExam(
    provider.attempts,
    exam,
  );

  if (paused != null) {
    if (paused.questions.isNotEmpty) {
      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => TestscreenWrapper(
            questions: paused.questions,
            instantMarking: true,
            licenceId: paused.licenceId ?? '',
            categoryId: paused.categoryId ?? '',
            licenceName: paused.licenceName ?? '',
            categoryName: paused.categoryName ?? '',
            initialQuestionIndex: paused.currentQuestionIndex,
            userSelections: paused.userSelections,
            resumeTestId: paused.testId,
            bcdCategoryId: paused.bcdCategoryId,
          ),
        ),
      ).then((_) {
        if (context.mounted) provider.refresh();
      });
    } else {
      final stats = provider.selectedStats;
      final continueNode = stats?.continueNode;
      if (continueNode != null) {
        launchBatch(context, exam, continueNode.node, null);
      }
    }
    return;
  }

  provider.selectExam(exam);
  final stats = provider.selectedStats;
  final continueNode = stats?.continueNode;
  if (continueNode != null) {
    launchBatch(context, exam, continueNode.node, null);
  }
}
