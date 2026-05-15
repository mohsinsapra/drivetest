import 'exam_node.dart';
import 'subscribed_exam.dart';

/// Enum for diagnosing what's holding a user back.
enum WeaknessType { none, lowScore, overTime, both }

/// Computed (not stored) stats for a single batch node.
class BatchStats {
  final ExamNode node;
  final int attempts;
  final double averageScore;
  final double bestScore;

  /// Sum of all attempt durations in seconds
  final int totalDurationSeconds;

  /// Average duration per attempt in seconds (0 if no attempts)
  final int avgDurationSeconds;

  /// From ExamNode.targetDurationSeconds
  final int targetDurationSeconds;

  final DateTime? lastAttemptDate;

  /// True if the user has passed this batch at least once
  final bool isCompleted;

  const BatchStats({
    required this.node,
    required this.attempts,
    required this.averageScore,
    required this.bestScore,
    required this.totalDurationSeconds,
    required this.avgDurationSeconds,
    required this.targetDurationSeconds,
    required this.lastAttemptDate,
    required this.isCompleted,
  });

  /// 0–100 progress: 100 if completed, otherwise avg score
  double get progressPercent =>
      isCompleted ? 100.0 : (attempts == 0 ? 0 : averageScore);

  /// ratio: avgDuration / target. < 1.0 = fast, > 1.0 = over time
  double get timeEfficiencyRatio => (targetDurationSeconds > 0 && attempts > 0)
      ? avgDurationSeconds / targetDurationSeconds
      : 1.0;

  bool get isOverTime => targetDurationSeconds > 0 && timeEfficiencyRatio > 1.1;
  bool get isLowScore => attempts > 0 && averageScore < 70;
  bool get isUntouched => attempts == 0;

  WeaknessType get weaknessType {
    if (isLowScore && isOverTime) return WeaknessType.both;
    if (isLowScore) return WeaknessType.lowScore;
    if (isOverTime) return WeaknessType.overTime;
    return WeaknessType.none;
  }

  String get timeLabel {
    if (avgDurationSeconds == 0) return '—';
    final m = avgDurationSeconds ~/ 60;
    final s = avgDurationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  String get targetTimeLabel {
    if (targetDurationSeconds == 0) return '—';
    final m = targetDurationSeconds ~/ 60;
    final s = targetDurationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}

/// Computed stats for a category node (only in 3-layer exams).
class CategoryStats {
  final ExamNode node;
  final List<BatchStats> batchStats;

  const CategoryStats({required this.node, required this.batchStats});

  double get averageScore {
    final withAttempts = batchStats.where((b) => b.attempts > 0).toList();
    if (withAttempts.isEmpty) return 0;
    return withAttempts.map((b) => b.averageScore).reduce((a, b) => a + b) /
        withAttempts.length;
  }

  int get completedBatches => batchStats.where((b) => b.isCompleted).length;
  int get totalBatches => batchStats.length;
  int get touchedBatches => batchStats.where((b) => b.attempts > 0).length;

  double get progressPercent =>
      totalBatches == 0 ? 0 : completedBatches / totalBatches * 100;

  int get totalDurationSeconds =>
      batchStats.fold(0, (sum, b) => sum + b.totalDurationSeconds);

  WeaknessType get dominantWeakness {
    final withAttempts = batchStats.where((b) => b.attempts > 0).toList();
    if (withAttempts.isEmpty) return WeaknessType.none;
    final lowScore = withAttempts.where((b) => b.isLowScore).length;
    final overTime = withAttempts.where((b) => b.isOverTime).length;
    if (lowScore > 0 && overTime > 0) return WeaknessType.both;
    if (lowScore > 0) return WeaknessType.lowScore;
    if (overTime > 0) return WeaknessType.overTime;
    return WeaknessType.none;
  }
}

/// Weekly streak summary, derived from TestAttempt dates.
class StreakSummary {
  final int currentStreak;
  final int bestStreak;
  final List<DateTime> thisWeekActiveDays;
  final int weeklyGoal;
  final int thisWeekActiveDayCount;

  const StreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.thisWeekActiveDays,
    required this.weeklyGoal,
    required this.thisWeekActiveDayCount,
  });

  bool isActiveDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return thisWeekActiveDays.any((a) => DateTime(a.year, a.month, a.day) == d);
  }
}

/// Full dashboard data for one exam — computed, not stored.
class ExamDashboardStats {
  final SubscribedExam exam;

  /// null if 2-layer exam
  final List<CategoryStats>? categoryStats;

  /// Direct batch stats (used for 2-layer; for 3-layer, iterate via categoryStats)
  final List<BatchStats> allBatchStats;

  final StreakSummary streak;

  /// Exam-level attempt count computed from bcdCategoryId matching — accurate
  /// even for historically-synced attempts where categoryId may be null.
  final int _examAttempts;

  const ExamDashboardStats({
    required this.exam,
    required this.categoryStats,
    required this.allBatchStats,
    required this.streak,
    int examAttempts = 0,
  }) : _examAttempts = examAttempts;

  double get overallProgressPercent {
    final batches = allBatchStats;
    if (batches.isEmpty) return 0;
    final completed = batches.where((b) => b.isCompleted).length;
    return completed / batches.length * 100;
  }

  /// Total attempts for this exam. Uses the exam-level count (by bcdCategoryId)
  /// when per-batch matching yields 0 — this handles historically-synced attempts
  /// that have a null categoryId from the backend.
  int get totalAttempts {
    final batchSum = allBatchStats.fold(0, (sum, b) => sum + b.attempts);
    return batchSum > 0 ? batchSum : _examAttempts;
  }

  int get completedBatchCount =>
      allBatchStats.where((b) => b.isCompleted).length;

  int get totalBatchCount => allBatchStats.length;

  int get avgDurationSeconds {
    final withAttempts = allBatchStats.where((b) => b.attempts > 0).toList();
    if (withAttempts.isEmpty) return 0;
    final total = withAttempts.fold(0, (sum, b) => sum + b.avgDurationSeconds);
    return total ~/ withAttempts.length;
  }

  /// The last attempted batch — shown as "Continue" so the user picks up
  /// exactly where they left off. Falls back to the first untouched batch
  /// if nothing has been attempted yet.
  BatchStats? get continueNode {
    // Most recently attempted batch
    final attempted =
        allBatchStats.where((b) => b.lastAttemptDate != null).toList();
    if (attempted.isNotEmpty) {
      attempted
          .sort((a, b) => b.lastAttemptDate!.compareTo(a.lastAttemptDate!));
      return attempted.first;
    }
    // Nothing attempted yet — suggest the first batch
    if (allBatchStats.isNotEmpty) return allBatchStats.first;
    return null;
  }

  BatchStats? get weakestBatch {
    final withAttempts = allBatchStats.where((b) => b.attempts > 0).toList();
    if (withAttempts.isEmpty) return null;
    return withAttempts
        .reduce((a, b) => a.averageScore < b.averageScore ? a : b);
  }

  BatchStats? get strongestBatch {
    final withAttempts = allBatchStats.where((b) => b.attempts > 0).toList();
    if (withAttempts.isEmpty) return null;
    return withAttempts
        .reduce((a, b) => a.averageScore > b.averageScore ? a : b);
  }

  CategoryStats? get weakestCategory {
    if (categoryStats == null) return null;
    final withTouched =
        categoryStats!.where((c) => c.touchedBatches > 0).toList();
    if (withTouched.isEmpty) return null;
    return withTouched
        .reduce((a, b) => a.averageScore < b.averageScore ? a : b);
  }

  double get overallAverageScore {
    final withAttempts = allBatchStats.where((b) => b.attempts > 0).toList();
    if (withAttempts.isEmpty) return 0;
    return withAttempts.map((b) => b.averageScore).reduce((a, b) => a + b) /
        withAttempts.length;
  }
}
