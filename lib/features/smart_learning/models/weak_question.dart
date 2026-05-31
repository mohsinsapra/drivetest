import 'package:hive/hive.dart';

part 'weak_question.g.dart';

@HiveType(typeId: 7)
class WeakQuestion extends HiveObject {
  @HiveField(0)
  final int testBcdId;

  @HiveField(1)
  final String questionId;

  @HiveField(2)
  int wrongCount;

  @HiveField(3)
  int correctStreak;

  @HiveField(4)
  DateTime lastSeen;

  WeakQuestion({
    required this.testBcdId,
    required this.questionId,
    this.wrongCount = 0,
    this.correctStreak = 0,
    required this.lastSeen,
  });
}
