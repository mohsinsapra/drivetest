// lib/core/router/route_args.dart
import 'package:taxi_exam_app/core/models/question.dart';

class TestScreenArgs {
  final List<Question> questions;
  final bool instantMarking;
  final String licenceId;
  final String categoryId;
  final String licenceName;
  final String categoryName;
  final int initialQuestionIndex;
  final Map<int, String>? userSelections;
  final bool isReviewMode;
  final bool isTimed;
  final int timeLimitMinutes;
  final double passScorePercent;
  final String? resumeTestId;
  final int? bcdCategoryId;
  final int? bcdTestId;
  final Set<String>? initiallySavedQuestionIds;

  const TestScreenArgs({
    required this.questions,
    required this.instantMarking,
    required this.licenceId,
    required this.categoryId,
    this.licenceName = '',
    this.categoryName = '',
    this.initialQuestionIndex = 0,
    this.userSelections,
    this.isReviewMode = false,
    this.isTimed = false,
    this.timeLimitMinutes = 10,
    this.passScorePercent = 70,
    this.resumeTestId,
    this.bcdCategoryId,
    this.bcdTestId,
    this.initiallySavedQuestionIds,
  });
}

class ResultScreenArgs {
  final List<Question> questions;
  final Map<int, String> userSelections;
  final String licenceId;
  final String categoryId;
  final bool hasPassed;

  const ResultScreenArgs({
    required this.questions,
    required this.userSelections,
    required this.licenceId,
    required this.categoryId,
    required this.hasPassed,
  });
}

class CustomTestScreenArgs {
  final String licenceId;
  final String categoryId;
  final String categoryName;

  const CustomTestScreenArgs({
    required this.licenceId,
    required this.categoryId,
    required this.categoryName,
  });
}

class SavedQuestionsArgs {
  final List<Question> questions;
  final String licenceId;
  final String categoryId;
  final String licenceName;
  final String categoryName;
  final int? bcdCategoryId;

  const SavedQuestionsArgs({
    required this.questions,
    required this.licenceId,
    required this.categoryId,
    required this.licenceName,
    required this.categoryName,
    this.bcdCategoryId,
  });
}

class BcdTestScreenArgs {
  final int testId;
  final String testName;
  final int passScore;
  final int timeLimit;
  final String parentCategoryName;
  final int? parentCategoryBcdId;

  const BcdTestScreenArgs({
    required this.testId,
    required this.testName,
    required this.passScore,
    required this.timeLimit,
    this.parentCategoryName = '',
    this.parentCategoryBcdId,
  });
}
