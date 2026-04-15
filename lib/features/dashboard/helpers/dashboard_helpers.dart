import 'package:taxi_exam_app/core/models/test_attempt.dart';
import '../models/dashboard_stats.dart';
import '../models/exam_node.dart';
import '../models/subscribed_exam.dart';

/// Pure helper functions. No Flutter imports — unit-testable.
class DashboardHelpers {
  DashboardHelpers._();

  // ─── Attempt filtering ────────────────────────────────────────────────────

  /// Returns completed attempts for a given batch node.
  ///
  /// BCD matching:
  ///   attempt.bcdCategoryId == (batchNode.parentId ?? exam.id)   ← direct parent
  ///   attempt.categoryId    == batchNode.id                       ← test id
  ///
  /// Legacy matching:
  ///   attempt.licenceId  == exam.id
  ///   attempt.categoryId == batchNode.id
  static List<TestAttempt> attemptsForBatch(
    List<TestAttempt> all,
    SubscribedExam exam,
    ExamNode batchNode,
  ) {
    if (exam.isBcd) {
      // For 2-layer: parentId is null → match against exam.id (top-level bcd_id)
      // For 3-layer: parentId is the subcategory bcd_id
      final expectedParentBcdId = batchNode.parentId ?? exam.id;
      return all.where((a) =>
        a.isBcd &&
        a.bcdCategoryId?.toString() == expectedParentBcdId &&
        a.categoryId == batchNode.id,
      ).toList();
    } else {
      return all.where((a) =>
        a.isCompleted &&
        a.licenceId == exam.id &&
        a.categoryId == batchNode.id,
      ).toList();
    }
  }

  // ─── Batch stats ──────────────────────────────────────────────────────────

  static BatchStats computeBatchStats(
    ExamNode node,
    List<TestAttempt> allAttempts,
    SubscribedExam exam,
  ) {
    final attempts = attemptsForBatch(allAttempts, exam, node);

    if (attempts.isEmpty) {
      return BatchStats(
        node: node,
        attempts: 0,
        averageScore: 0,
        bestScore: 0,
        totalDurationSeconds: 0,
        avgDurationSeconds: 0,
        targetDurationSeconds: node.targetDurationSeconds,
        lastAttemptDate: null,
        isCompleted: false,
      );
    }

    final scores = attempts.map((a) => a.score).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final best = scores.reduce((a, b) => a > b ? a : b);

    final durations = attempts
        .where((a) => (a.durationSeconds ?? 0) > 0)
        .map((a) => a.durationSeconds!)
        .toList();
    final totalDur = durations.isEmpty ? 0 : durations.reduce((a, b) => a + b);
    final avgDur = durations.isEmpty ? 0 : totalDur ~/ durations.length;

    final passed = attempts.any((a) => a.hasPassed);
    attempts.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return BatchStats(
      node: node,
      attempts: attempts.length,
      averageScore: avg,
      bestScore: best,
      totalDurationSeconds: totalDur,
      avgDurationSeconds: avgDur,
      targetDurationSeconds: node.targetDurationSeconds,
      lastAttemptDate: attempts.first.dateTime,
      isCompleted: passed,
    );
  }

  // ─── Category stats ───────────────────────────────────────────────────────

  static CategoryStats computeCategoryStats(
    ExamNode categoryNode,
    SubscribedExam exam,
    List<TestAttempt> allAttempts,
  ) {
    final batches = exam.childrenOf(categoryNode.id);
    final batchStats = batches
        .map((b) => computeBatchStats(b, allAttempts, exam))
        .toList();
    return CategoryStats(node: categoryNode, batchStats: batchStats);
  }

  // ─── Full exam dashboard stats ────────────────────────────────────────────

  static ExamDashboardStats computeExamStats(
    SubscribedExam exam,
    List<TestAttempt> allAttempts,
  ) {
    List<CategoryStats>? categoryStats;
    List<BatchStats> allBatchStats;

    if (exam.hasCategories) {
      categoryStats = exam.allCategories
          .map((c) => computeCategoryStats(c, exam, allAttempts))
          .toList();
      allBatchStats = categoryStats.expand((c) => c.batchStats).toList();
    } else {
      allBatchStats = exam.allBatches
          .map((b) => computeBatchStats(b, allAttempts, exam))
          .toList();
    }

    final streak = computeStreakSummary(allAttempts, exam: exam);

    return ExamDashboardStats(
      exam: exam,
      categoryStats: categoryStats,
      allBatchStats: allBatchStats,
      streak: streak,
    );
  }

  // ─── Overall exam progress (for overview card) ────────────────────────────

  static double overallProgressPercent(
    SubscribedExam exam,
    List<TestAttempt> allAttempts,
  ) {
    final batches = exam.allBatches;
    if (batches.isEmpty) return 0;
    final completed = batches.where((b) {
      final attempts = attemptsForBatch(allAttempts, exam, b);
      return attempts.any((a) => a.hasPassed);
    }).length;
    return completed / batches.length * 100;
  }

  // ─── Streak ───────────────────────────────────────────────────────────────

  /// Computes streak data scoped to [exam], or global if null.
  static StreakSummary computeStreakSummary(
    List<TestAttempt> allAttempts, {
    SubscribedExam? exam,
  }) {
    final relevant = allAttempts.where((a) {
      if (exam == null) return true;
      if (exam.isBcd) {
        if (!a.isBcd) return false;
        // Any attempt whose direct parent belongs to this exam's tree
        final validParentIds = {
          exam.id,
          ...exam.allCategories.map((c) => c.id),
        };
        return validParentIds.contains(a.bcdCategoryId?.toString());
      } else {
        return a.isCompleted && a.licenceId == exam.id;
      }
    }).toList();

    // Unique active dates normalised to midnight
    final activeDates = relevant
        .map((a) => DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day))
        .toSet()
        .toList()
      ..sort();

    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);

    // Current streak (backwards from today, with yesterday grace)
    int currentStreak = 0;
    DateTime check = todayMid;
    while (activeDates.contains(check)) {
      currentStreak++;
      check = check.subtract(const Duration(days: 1));
    }
    if (currentStreak == 0) {
      check = todayMid.subtract(const Duration(days: 1));
      while (activeDates.contains(check)) {
        currentStreak++;
        check = check.subtract(const Duration(days: 1));
      }
    }

    // Best streak
    int bestStreak = 0;
    int running = 0;
    for (int i = 0; i < activeDates.length; i++) {
      if (i == 0) {
        running = 1;
      } else {
        final diff = activeDates[i].difference(activeDates[i - 1]).inDays;
        running = diff == 1 ? running + 1 : 1;
      }
      if (running > bestStreak) bestStreak = running;
    }

    // This week Mon–Sun
    final monday = todayMid.subtract(Duration(days: todayMid.weekday - 1));
    final thisWeek = List.generate(7, (i) => monday.add(Duration(days: i)));
    final thisWeekActive = thisWeek.where((d) => activeDates.contains(d)).toList();

    return StreakSummary(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      thisWeekActiveDays: thisWeekActive,
      weeklyGoal: 5,
      thisWeekActiveDayCount: thisWeekActive.length,
    );
  }

  // ─── Formatting ───────────────────────────────────────────────────────────

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  static String formatScore(double score) => '${score.toStringAsFixed(0)}%';
}
