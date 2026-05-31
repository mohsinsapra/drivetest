import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/features/smart_learning/models/smart_progress.dart';
import 'package:taxi_exam_app/features/smart_learning/models/weak_question.dart';

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

  /// Total weak questions across multiple tests (for category-level mistakes).
  Future<int> weakQuestionCountForTests(List<int> testBcdIds) async {
    final box = await AppStorage.weakQuestionsBox();
    final idSet = testBcdIds.toSet();
    return box.values.where((wq) => idSet.contains(wq.testBcdId)).length;
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
