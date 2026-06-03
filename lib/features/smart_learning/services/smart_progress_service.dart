import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/features/smart_learning/models/smart_progress.dart';
import 'package:taxi_exam_app/features/smart_learning/models/weak_question.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/smart_utils.dart';

class SmartProgressService {
  static final SmartProgressService _instance = SmartProgressService._();
  factory SmartProgressService() => _instance;
  SmartProgressService._();

  String _chunkKey(int testBcdId, int chunkIndex) => '$testBcdId-$chunkIndex';
  String _weakKey(int testBcdId, String questionId) => '$testBcdId-$questionId';

  /// Returns the 0-based index of the first unpassed chunk.
  /// Returns [totalChunks] when all chunks are passed.
  Future<int> activeSmartIndex(int testBcdId, int totalChunks) async {
    final box = await AppStorage.smartProgressBox();
    for (var i = 0; i < totalChunks; i++) {
      final entry = box.get(_chunkKey(testBcdId, i));
      if (entry == null || !entry.isPassed) return i;
    }
    return totalChunks;
  }

  /// True when all [totalChunks] chunks have isPassed = true.
  Future<bool> isFullExamUnlocked(int testBcdId, int totalChunks) async {
    return await activeSmartIndex(testBcdId, totalChunks) >= totalChunks;
  }

  /// Persists pass/fail result for one chunk attempt.
  Future<void> recordSmartResult(
      int testBcdId, int chunkIndex, bool passed) async {
    final box = await AppStorage.smartProgressBox();
    await box.put(
      _chunkKey(testBcdId, chunkIndex),
      SmartProgress(
        testBcdId: testBcdId,
        chunkIndex: chunkIndex,
        isPassed: passed,
        completedAt: DateTime.now(),
      ),
    );
  }

  /// Updates the weak pool from session results.
  ///
  /// [questionResults]: `Map<questionId, wasCorrect>`
  /// - Wrong  → wrongCount++, correctStreak reset to 0 (added if new)
  /// - Correct → correctStreak++; if >= 2 consecutive correct sessions → graduated (deleted)
  Future<void> recordSessionResults(
      int testBcdId, Map<String, bool> questionResults) async {
    final box = await AppStorage.weakQuestionsBox();
    for (final entry in questionResults.entries) {
      final key = _weakKey(testBcdId, entry.key);
      final wasCorrect = entry.value;
      final existing = box.get(key);

      if (existing != null) {
        if (wasCorrect) {
          existing.correctStreak++;
          if (existing.correctStreak >= 2) {
            await box.delete(key);
            continue;
          }
        } else {
          existing.wrongCount++;
          existing.correctStreak = 0;
        }
        existing.lastSeen = DateTime.now();
        await existing.save();
      } else if (!wasCorrect) {
        await box.put(
          key,
          WeakQuestion(
            testBcdId: testBcdId,
            questionId: entry.key,
            wrongCount: 1,
            correctStreak: 0,
            lastSeen: DateTime.now(),
          ),
        );
      }
    }
  }

  /// Returns up to `floor(chunkSize * 0.3)` weak question IDs for [testBcdId],
  /// sorted by wrongCount descending (most-wrong first).
  Future<List<String>> weakQuestionIdsFor(int testBcdId, int chunkSize) async {
    final box = await AppStorage.weakQuestionsBox();
    final cap = (chunkSize * 0.3).floor();
    final weak = box.values.where((wq) => wq.testBcdId == testBcdId).toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return weak.take(cap).map((wq) => wq.questionId).toList();
  }

  /// Returns all weak question IDs for [testBcdId] (for Train Mistakes mode).
  Future<List<String>> allWeakQuestionIds(int testBcdId) async {
    final box = await AppStorage.weakQuestionsBox();
    final weak = box.values.where((wq) => wq.testBcdId == testBcdId).toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return weak.map((wq) => wq.questionId).toList();
  }

  /// Total count of weak questions for [testBcdId].
  Future<int> weakQuestionCount(int testBcdId) async {
    final box = await AppStorage.weakQuestionsBox();
    return box.values.where((wq) => wq.testBcdId == testBcdId).length;
  }

  /// Most recent [completedAt] per testBcdId, for any testBcdIds in the list.
  Future<Map<int, DateTime>> lastActivityDates(List<int> testBcdIds) async {
    final box = await AppStorage.smartProgressBox();
    final idSet = testBcdIds.toSet();
    final result = <int, DateTime>{};
    for (final entry in box.values) {
      if (!idSet.contains(entry.testBcdId)) continue;
      final existing = result[entry.testBcdId];
      if (existing == null || entry.completedAt.isAfter(existing)) {
        result[entry.testBcdId] = entry.completedAt;
      }
    }
    return result;
  }

  /// Single-pass batch: opens the smartProgress box once and returns both
  /// active smart indices and last activity dates for all given tests.
  ///
  /// [testChunkCounts] maps testBcdId → total number of chunks.
  Future<({Map<int, int> passedCounts, Map<int, DateTime> activityDates})>
      batchProgress(Map<int, int> testChunkCounts) async {
    final box = await AppStorage.smartProgressBox();

    // Activity dates — one pass through all stored entries.
    final activityDates = <int, DateTime>{};
    for (final entry in box.values) {
      if (!testChunkCounts.containsKey(entry.testBcdId)) continue;
      final existing = activityDates[entry.testBcdId];
      if (existing == null || entry.completedAt.isAfter(existing)) {
        activityDates[entry.testBcdId] = entry.completedAt;
      }
    }

    // Pass counts — per-test sequential chunk check (box.get is O(1) in Hive).
    final passedCounts = <int, int>{};
    for (final kv in testChunkCounts.entries) {
      final testBcdId = kv.key;
      final totalChunks = kv.value;
      var index = totalChunks;
      for (var i = 0; i < totalChunks; i++) {
        final entry = box.get(_chunkKey(testBcdId, i));
        if (entry == null || !entry.isPassed) {
          index = i;
          break;
        }
      }
      passedCounts[testBcdId] = index;
    }

    return (passedCounts: passedCounts, activityDates: activityDates);
  }

  /// Total weak questions across multiple tests (for category-level mistakes).
  Future<int> weakQuestionCountForTests(List<int> testBcdIds) async {
    final box = await AppStorage.weakQuestionsBox();
    final idSet = testBcdIds.toSet();
    return box.values.where((wq) => idSet.contains(wq.testBcdId)).length;
  }

  /// Smart stats for one exam: chunks mastered, total chunks, weak question count.
  /// [examBcdId] = int.parse(SubscribedExam.id) for BCD exams.
  Future<({int chunksMastered, int chunksTotal, int weakQuestions})>
      examSmartStats(int examBcdId) async {
    final statsByExam = await examSmartStatsByExam([examBcdId]);
    return statsByExam[examBcdId] ??
        (chunksMastered: 0, chunksTotal: 0, weakQuestions: 0);
  }

  /// Bulk smart stats for multiple exams. Opens Hive boxes once and reuses
  /// a single weak-question scan across all requested exams.
  Future<Map<int, ({int chunksMastered, int chunksTotal, int weakQuestions})>>
      examSmartStatsByExam(Iterable<int> examBcdIds) async {
    final examIds = examBcdIds.toSet();
    if (examIds.isEmpty) return const {};

    final chunkCountsByExam = <int, Map<int, int>>{};
    for (final examBcdId in examIds) {
      chunkCountsByExam[examBcdId] = _collectTestChunkCounts(examBcdId);
    }

    final progressBox = await AppStorage.smartProgressBox();
    final weakBox = await AppStorage.weakQuestionsBox();
    final weakByTest = <int, int>{};
    for (final weak in weakBox.values) {
      weakByTest.update(weak.testBcdId, (count) => count + 1, ifAbsent: () => 1);
    }

    final result =
        <int, ({int chunksMastered, int chunksTotal, int weakQuestions})>{};
    for (final examBcdId in examIds) {
      final testChunkCounts = chunkCountsByExam[examBcdId]!;
      if (testChunkCounts.isEmpty) {
        result[examBcdId] =
            (chunksMastered: 0, chunksTotal: 0, weakQuestions: 0);
        continue;
      }

      int chunksMastered = 0;
      int chunksTotal = 0;
      int weakQuestions = 0;
      for (final kv in testChunkCounts.entries) {
        final testBcdId = kv.key;
        final total = kv.value;
        chunksTotal += total;
        weakQuestions += weakByTest[testBcdId] ?? 0;
        for (var i = 0; i < total; i++) {
          final entry = progressBox.get(_chunkKey(testBcdId, i));
          if (entry != null && entry.isPassed) chunksMastered++;
        }
      }

      result[examBcdId] = (
        chunksMastered: chunksMastered,
        chunksTotal: chunksTotal,
        weakQuestions: weakQuestions,
      );
    }

    return result;
  }

  /// Builds testBcdId → chunkCount map for all tests in [examBcdId] via BcdCache.
  Map<int, int> _collectTestChunkCounts(int examBcdId) {
    final result = <int, int>{};
    final cache = BcdCache.instance;
    final cats = cache.categories.where((c) => c['bcd_id'] == examBcdId);
    for (final cat in cats) {
      final catId = cat['bcd_id'] as int;
      final hasSubs = cat['has_children'] == true;
      if (hasSubs) {
        for (final sub in cache.subcategoriesOf(catId)) {
          final subId = sub['bcd_id'] as int;
          for (final test in cache.testsOf(subId)) {
            final qc = test['question_count'] as int? ?? 0;
            if (qc == 0) continue;
            result[test['bcd_id'] as int] =
                SmartUtils.computeSmartSizes(qc).length;
          }
        }
      } else {
        for (final test in cache.testsOf(catId)) {
          final qc = test['question_count'] as int? ?? 0;
          if (qc == 0) continue;
          result[test['bcd_id'] as int] =
              SmartUtils.computeSmartSizes(qc).length;
        }
      }
    }
    return result;
  }

  /// All weak questions grouped by testBcdId, for category-level mistakes session.
  Future<Map<int, List<String>>> weakQuestionIdsByTest(
      List<int> testBcdIds) async {
    final box = await AppStorage.weakQuestionsBox();
    final idSet = testBcdIds.toSet();
    final result = <int, List<String>>{};
    for (final wq in box.values.where((wq) => idSet.contains(wq.testBcdId))) {
      result.putIfAbsent(wq.testBcdId, () => []).add(wq.questionId);
    }
    return result;
  }

  /// Number of questions the user has mastered for [testBcdId].
  ///
  /// A question is considered mastered when its chunk has been passed (≥70%
  /// correct). Returns the sum of question counts for all passed chunks.
  Future<int> masteredQuestionCount(int testBcdId, List<int> chunkSizes) async {
    final box = await AppStorage.smartProgressBox();
    int count = 0;
    for (int i = 0; i < chunkSizes.length; i++) {
      final entry = box.get(_chunkKey(testBcdId, i));
      if (entry != null && entry.isPassed) count += chunkSizes[i];
    }
    return count;
  }
}
