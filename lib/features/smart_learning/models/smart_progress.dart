import 'package:hive/hive.dart';

part 'smart_progress.g.dart';

@HiveType(typeId: 6)
class SmartProgress extends HiveObject {
  @HiveField(0)
  final int testBcdId;

  @HiveField(1)
  final int chunkIndex;

  @HiveField(2)
  final bool isPassed;

  @HiveField(3)
  final DateTime completedAt;

  SmartProgress({
    required this.testBcdId,
    required this.chunkIndex,
    required this.isPassed,
    required this.completedAt,
  });
}
