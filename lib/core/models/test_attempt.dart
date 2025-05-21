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

  TestAttempt({
    required this.testId,
    required this.dateTime,
    required this.userSelections,
    required this.score,
    required this.hasPassed,
    required this.questions,
  });
}
