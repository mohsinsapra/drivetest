// models/test_attempt.dart
import 'package:hive/hive.dart';
import 'package:taxi_exam_app/core/models/question.dart';

part 'test_attempt.g.dart';

@HiveType(typeId: 0)
class TestAttempt extends HiveObject {
  @HiveField(0)
  String testId;

  @HiveField(1)
  DateTime dateTime;

  @HiveField(2)
  Map<int, String> userSelections;

  @HiveField(3)
  double score;

  @HiveField(4)
  bool hasPassed;

  @HiveField(5)
  List<Question> questions;

  @HiveField(6)
  String? licenceName;

  @HiveField(7)
  String? categoryName;

  @HiveField(8)
  String status; // 'completed' or 'paused'

  @HiveField(9)
  int currentQuestionIndex;

  @HiveField(10)
  String? licenceId;

  @HiveField(11)
  String? categoryId;

  @HiveField(12)
  int? durationSeconds;

  @HiveField(13)
  int? bcdCategoryId;

  TestAttempt({
    required this.testId,
    required this.dateTime,
    required this.userSelections,
    required this.score,
    required this.hasPassed,
    required this.questions,
    required this.licenceName,
    required this.categoryName,
    this.status = 'completed',
    this.currentQuestionIndex = 0,
    this.licenceId,
    this.categoryId,
    this.durationSeconds,
    this.bcdCategoryId,
  });

  bool get isPaused => status == 'paused';
  bool get isStarted => status == 'started';
  /// True for any attempt the user can resume (started or paused).
  bool get isResumable => status == 'started' || status == 'paused';
  bool get isCompleted => status == 'completed';
  bool get isBcd => bcdCategoryId != null;
}
