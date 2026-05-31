import 'dart:math';
import 'package:collection/collection.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/smart_utils.dart';

/// Builds the question list for one chunk session.
///
/// Base questions are the same every retry for a given [chunkIndex].
/// Weak questions from previous sessions are injected (capped at 30%
/// of chunk size), excluding any already in the base slice.
class SmartSessionBuilder {
  SmartSessionBuilder._();

  static List<Question> build({
    required List<Question> allQuestions,
    required List<int> chunkSizes,
    required int chunkIndex,
    required List<String> weakQuestionIds,
  }) {
    final offset = SmartUtils.smartOffset(chunkSizes, chunkIndex);
    final size = chunkSizes[chunkIndex];
    final base = allQuestions.sublist(offset, offset + size);

    final baseIds = base.map((q) => q.questionId).toSet();
    final cap = (size * 0.3).floor();
    final weak = weakQuestionIds
        .where((id) => !baseIds.contains(id))
        .take(cap)
        .map((id) => allQuestions.firstWhereOrNull((q) => q.questionId == id))
        .whereType<Question>()
        .toList();

    return [...base, ...weak]..shuffle(Random());
  }
}

/// Manages the mutable question queue for a single chunk session.
///
/// Wrong answers are silently re-inserted once at a random later position.
/// Score is based on first attempts only — re-asks do not inflate or deflate it.
class SmartQueueManager {
  final List<Question> _queue;
  final Set<String> _reAsked = {};
  int _cursor = 0;
  final Map<String, bool> _firstAttempts = {};

  SmartQueueManager(List<Question> questions)
      : _queue = List<Question>.from(questions);

  bool get isDone => _cursor >= _queue.length;

  Question get current => _queue[_cursor];

  /// First-attempt results: `Map<questionId, wasCorrect>`.
  /// Pass this to SmartProgressService.recordSessionResults().
  Map<String, bool> get firstAttempts => Map.unmodifiable(_firstAttempts);

  /// Score = correctly answered on first attempt / total unique questions.
  double get score {
    if (_firstAttempts.isEmpty) return 0;
    final correct = _firstAttempts.values.where((v) => v).length;
    return correct / _firstAttempts.length;
  }

  void answer(bool correct) {
    final q = current;
    _firstAttempts[q.questionId] ??= correct;

    if (!correct && !_reAsked.contains(q.questionId)) {
      final remaining = _queue.length - _cursor - 1;
      if (remaining > 0) {
        final insertAt = _cursor + 1 + Random().nextInt(remaining);
        _queue.insert(insertAt, q);
      } else {
        _queue.add(q);
      }
      _reAsked.add(q.questionId);
    }
    _cursor++;
  }
}
