import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/tests/test_attempt_save_service.dart';

void main() {
  group('TestAttemptSaveService', () {
    test('stores locally before syncing backend', () async {
      final events = <String>[];
      final service = TestAttemptSaveService(
        saveLocal: (attempt) async {
          events.add('local:${attempt.testId}');
        },
        syncRemote: (attempt) async {
          events.add('remote:${attempt.testId}');
          return true;
        },
      );

      final result = await service.save(_attempt());

      expect(result.localSaved, isTrue);
      expect(result.backendSynced, isTrue);
      expect(events, ['local:t1', 'remote:t1']);
    });

    test('keeps local save even when backend sync fails', () async {
      final events = <String>[];
      final service = TestAttemptSaveService(
        saveLocal: (attempt) async {
          events.add('local:${attempt.testId}');
        },
        syncRemote: (attempt) async {
          events.add('remote:${attempt.testId}');
          return false;
        },
      );

      final result = await service.save(_attempt());

      expect(result.localSaved, isTrue);
      expect(result.backendSynced, isFalse);
      expect(events, ['local:t1', 'remote:t1']);
    });
  });
}

TestAttempt _attempt() {
  return TestAttempt(
    testId: 't1',
    dateTime: DateTime(2026, 5, 16),
    userSelections: const {0: 'a'},
    score: 10,
    hasPassed: false,
    questions: [
      Question(
        questionId: 'q1',
        text: 'Question',
        options: [
          Option(optionLabel: 'a', text: 'A', imageUrl: ''),
          Option(optionLabel: 'b', text: 'B', imageUrl: ''),
        ],
        correctAnswer: 'a',
        imageUrl: '',
        answerExplanation: '',
      ),
    ],
    licenceName: 'L',
    categoryName: 'C',
    status: 'paused',
    currentQuestionIndex: 0,
    licenceId: '1',
    categoryId: '2',
    durationSeconds: 12,
  );
}
