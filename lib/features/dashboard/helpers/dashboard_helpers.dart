import 'package:taxi_exam_app/core/models/test_attempt.dart';
import '../models/dashboard_stats.dart';
import '../models/exam_node.dart';
import '../models/subscribed_exam.dart';

/// Pure helper functions. No Flutter imports — unit-testable.
class DashboardHelpers {
  DashboardHelpers._();

  // ─── Attempt filtering ────────────────────────────────────────────────────

  /// Returns all attempts for a given batch node.
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
      final expectedParentBcdId = batchNode.parentId ?? exam.id;
      return all.where((a) {
        if (a.isBcd) {
          if (a.bcdCategoryId?.toString() != expectedParentBcdId) return false;
          return a.categoryId == batchNode.id ||
              (a.categoryId == null && a.categoryName == batchNode.name);
        }
        return a.categoryName != null && a.categoryName == batchNode.name;
      }).toList();
    } else {
      return all
          .where(
            (a) =>
                a.isCompleted &&
                a.licenceId == exam.id &&
                a.categoryId == batchNode.id,
          )
          .toList();
    }
  }

  // ─── Batch stats ──────────────────────────────────────────────────────────

  static BatchStats computeBatchStats(
    ExamNode node,
    List<TestAttempt> allAttempts,
    SubscribedExam exam,
  ) {
    final attempts = attemptsForBatch(allAttempts, exam, node);
    return _batchStatsFromAttempts(node, attempts, attempts);
  }

  // ─── Category stats ───────────────────────────────────────────────────────

  static CategoryStats computeCategoryStats(
    ExamNode categoryNode,
    SubscribedExam exam,
    List<TestAttempt> allAttempts,
  ) {
    final batches = exam.childrenOf(categoryNode.id);
    final batchStats =
        batches.map((b) => computeBatchStats(b, allAttempts, exam)).toList();
    return CategoryStats(node: categoryNode, batchStats: batchStats);
  }

  // ─── Full exam dashboard stats ────────────────────────────────────────────

  /// Computes full stats for [exam] in O(n_attempts + n_batches) by building
  /// a lookup index once instead of scanning all attempts per batch.
  ///
  /// [periodAttempts] are filtered by the active period and used for stats.
  /// [allAttempts] is the full unfiltered list and is used to populate
  /// [BatchStats.sortedAttempts] for history display, avoiding repeated
  /// filtering inside build().
  static ExamDashboardStats computeExamStats(
    SubscribedExam exam,
    List<TestAttempt> periodAttempts,
    List<TestAttempt> allAttempts, {
    int weeklyGoal = 5,
  }) {
    final periodIndex = _AttemptsIndex(periodAttempts);
    final allIndex = _AttemptsIndex(allAttempts);

    List<CategoryStats>? categoryStats;
    List<BatchStats> allBatchStats;

    if (exam.hasCategories) {
      categoryStats = exam.allCategories
          .map((c) => _categoryStatsIndexed(c, exam, periodIndex, allIndex))
          .toList();
      allBatchStats = categoryStats.expand((c) => c.batchStats).toList();
    } else {
      allBatchStats = exam.allBatches
          .map((b) => _batchStatsIndexed(b, exam, periodIndex, allIndex))
          .toList();
    }

    final streak =
        computeStreakSummary(allAttempts, exam: exam, weeklyGoal: weeklyGoal);
    final examAttempts = _examLevelAttemptCount(allAttempts, exam);

    return ExamDashboardStats(
      exam: exam,
      categoryStats: categoryStats,
      allBatchStats: allBatchStats,
      streak: streak,
      examAttempts: examAttempts,
    );
  }

  static CategoryStats _categoryStatsIndexed(
    ExamNode categoryNode,
    SubscribedExam exam,
    _AttemptsIndex periodIndex,
    _AttemptsIndex allIndex,
  ) {
    final batches = exam.childrenOf(categoryNode.id);
    final batchStats = batches
        .map((b) => _batchStatsIndexed(b, exam, periodIndex, allIndex))
        .toList();
    return CategoryStats(node: categoryNode, batchStats: batchStats);
  }

  static BatchStats _batchStatsIndexed(
    ExamNode node,
    SubscribedExam exam,
    _AttemptsIndex periodIndex,
    _AttemptsIndex allIndex,
  ) {
    final periodAttempts = periodIndex.forBatch(exam, node);
    final allBatchAttempts = allIndex.forBatch(exam, node);
    return _batchStatsFromAttempts(node, periodAttempts, allBatchAttempts);
  }

  /// Shared computation given a pre-filtered list of attempts for one batch.
  /// [periodAttempts] drive the stats; [allAttempts] are stored sorted for UI.
  static BatchStats _batchStatsFromAttempts(
    ExamNode node,
    List<TestAttempt> periodAttempts,
    List<TestAttempt> allAttempts,
  ) {
    // Sort the full history list once here — reused by build() via sortedAttempts.
    allAttempts.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (periodAttempts.isEmpty) {
      return BatchStats(
        node: node,
        attempts: 0,
        averageScore: 0,
        bestScore: 0,
        totalDurationSeconds: 0,
        avgDurationSeconds: 0,
        targetDurationSeconds: node.targetDurationSeconds,
        lastAttemptDate: allAttempts.isNotEmpty ? allAttempts.first.dateTime : null,
        isCompleted: allAttempts.any((a) => a.hasPassed),
        sortedAttempts: allAttempts,
      );
    }

    final scores = periodAttempts.map((a) => a.score).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final best = scores.reduce((a, b) => a > b ? a : b);

    final durations = periodAttempts
        .where((a) => (a.durationSeconds ?? 0) > 0)
        .map((a) => a.durationSeconds!)
        .toList();
    final totalDur = durations.isEmpty ? 0 : durations.reduce((a, b) => a + b);
    final avgDur = durations.isEmpty ? 0 : totalDur ~/ durations.length;

    final passed = periodAttempts.any((a) => a.hasPassed);
    periodAttempts.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return BatchStats(
      node: node,
      attempts: periodAttempts.length,
      averageScore: avg,
      bestScore: best,
      totalDurationSeconds: totalDur,
      avgDurationSeconds: avgDur,
      targetDurationSeconds: node.targetDurationSeconds,
      lastAttemptDate: periodAttempts.first.dateTime,
      isCompleted: passed,
      sortedAttempts: allAttempts,
    );
  }

  /// Counts all attempts that belong to [exam] using broad bcdCategoryId matching.
  static int _examLevelAttemptCount(
    List<TestAttempt> all,
    SubscribedExam exam,
  ) {
    if (exam.isBcd) {
      final validParentIds = {
        exam.id,
        ...exam.allCategories.map((c) => c.id),
      };
      final batchNames = exam.allBatches.map((b) => b.name).toSet();
      return all
          .where((a) =>
              (a.isBcd &&
                  validParentIds.contains(a.bcdCategoryId?.toString())) ||
              (!a.isBcd &&
                  a.categoryName != null &&
                  batchNames.contains(a.categoryName)))
          .length;
    } else {
      return all.where((a) => a.isCompleted && a.licenceId == exam.id).length;
    }
  }

  // ─── Overall exam progress (for overview card) ────────────────────────────

  /// Builds progress % for every exam in one pass — index created once.
  static Map<String, double> buildOverviewProgress(
    List<SubscribedExam> exams,
    List<TestAttempt> allAttempts,
  ) {
    if (exams.isEmpty) return {};
    final index = _AttemptsIndex(allAttempts);
    return {for (final e in exams) e.id: _progressPercent(e, index)};
  }

  static double _progressPercent(SubscribedExam exam, _AttemptsIndex index) {
    final batches = exam.allBatches;
    if (batches.isEmpty) return 0;
    final completed = batches
        .where((b) => index.forBatch(exam, b).any((a) => a.hasPassed))
        .length;
    return completed / batches.length * 100;
  }

  static double overallProgressPercent(
    SubscribedExam exam,
    List<TestAttempt> allAttempts,
  ) =>
      _progressPercent(exam, _AttemptsIndex(allAttempts));

  // ─── Streak ───────────────────────────────────────────────────────────────

  /// Computes streak data scoped to [exam], or global if null.
  static StreakSummary computeStreakSummary(
    List<TestAttempt> allAttempts, {
    SubscribedExam? exam,
    int weeklyGoal = 5,
  }) {
    final relevant = allAttempts.where((a) {
      if (exam == null) return true;
      if (exam.isBcd) {
        final validParentIds = {
          exam.id,
          ...exam.allCategories.map((c) => c.id),
        };
        if (a.isBcd) {
          return validParentIds.contains(a.bcdCategoryId?.toString());
        }
        final batchNames = exam.allBatches.map((b) => b.name).toSet();
        return a.categoryName != null && batchNames.contains(a.categoryName);
      } else {
        return a.isCompleted && a.licenceId == exam.id;
      }
    }).toList();

    final activeDatesSet = relevant
        .map((a) => DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day))
        .toSet();
    final activeDates = activeDatesSet.toList()..sort();

    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);

    int currentStreak = 0;
    DateTime check = todayMid;
    while (activeDatesSet.contains(check)) {
      currentStreak++;
      check = check.subtract(const Duration(days: 1));
    }
    if (currentStreak == 0) {
      check = todayMid.subtract(const Duration(days: 1));
      while (activeDatesSet.contains(check)) {
        currentStreak++;
        check = check.subtract(const Duration(days: 1));
      }
    }

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

    final monday = todayMid.subtract(Duration(days: todayMid.weekday - 1));
    final thisWeek = List.generate(7, (i) => monday.add(Duration(days: i)));
    final thisWeekActive = thisWeek.where(activeDatesSet.contains).toList();

    return StreakSummary(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      thisWeekActiveDays: thisWeekActive,
      weeklyGoal: weeklyGoal,
      thisWeekActiveDayCount: thisWeekActive.length,
    );
  }

  // ─── Paused attempt lookup ─────────────────────────────────────────────────

  /// Returns the most recent paused attempt that belongs to [exam], or null.
  static TestAttempt? latestPausedAttemptForExam(
    List<TestAttempt> all,
    SubscribedExam exam,
  ) {
    final batchNames = exam.allBatches.map((b) => b.name).toSet();
    final validParentIds = {
      exam.id,
      ...exam.allCategories.map((c) => c.id),
    };

    final paused = all.where((a) {
      if (!a.isPaused) return false;
      if (exam.isBcd) {
        if (a.isBcd) {
          return validParentIds.contains(a.bcdCategoryId?.toString());
        }
        return a.categoryName != null && batchNames.contains(a.categoryName);
      }
      return a.licenceId == exam.id;
    }).toList();

    if (paused.isEmpty) return null;
    paused.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return paused.first;
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

// ─── Attempts lookup index ────────────────────────────────────────────────────
//
// Built once per computeExamStats call in O(n_attempts).
// Reduces per-batch filtering from O(n_attempts) to O(1).

class _AttemptsIndex {
  // Modern BCD: bcdCategoryId + categoryId
  final Map<String, List<TestAttempt>> _byId;
  // Modern BCD: bcdCategoryId + categoryName (when categoryId is null)
  final Map<String, List<TestAttempt>> _byName;
  // Legacy BCD (bcdCategoryId == null): categoryName only
  final Map<String, List<TestAttempt>> _legacyByName;
  // Non-BCD: licenceId + categoryId (completed only)
  final Map<String, List<TestAttempt>> _nonBcd;

  factory _AttemptsIndex(List<TestAttempt> attempts) {
    final byId = <String, List<TestAttempt>>{};
    final byName = <String, List<TestAttempt>>{};
    final legacyByName = <String, List<TestAttempt>>{};
    final nonBcd = <String, List<TestAttempt>>{};

    for (final a in attempts) {
      if (a.isBcd) {
        final pid = a.bcdCategoryId!.toString();
        if (a.categoryId != null) {
          (byId['$pid|${a.categoryId}'] ??= []).add(a);
        } else if (a.categoryName != null) {
          (byName['$pid|${a.categoryName}'] ??= []).add(a);
        }
      } else {
        if (a.categoryName != null) {
          (legacyByName[a.categoryName!] ??= []).add(a);
        }
        if (a.isCompleted && a.licenceId != null && a.categoryId != null) {
          (nonBcd['${a.licenceId}|${a.categoryId}'] ??= []).add(a);
        }
      }
    }

    return _AttemptsIndex._(byId, byName, legacyByName, nonBcd);
  }

  const _AttemptsIndex._(
    this._byId,
    this._byName,
    this._legacyByName,
    this._nonBcd,
  );

  List<TestAttempt> forBatch(SubscribedExam exam, ExamNode batchNode) {
    if (exam.isBcd) {
      final pid = batchNode.parentId ?? exam.id;
      final result = <TestAttempt>[];
      final byId = _byId['$pid|${batchNode.id}'];
      if (byId != null) result.addAll(byId);
      final byName = _byName['$pid|${batchNode.name}'];
      if (byName != null) result.addAll(byName);
      final legacy = _legacyByName[batchNode.name];
      if (legacy != null) result.addAll(legacy);
      return result;
    } else {
      return _nonBcd['${exam.id}|${batchNode.id}'] ?? const [];
    }
  }
}
