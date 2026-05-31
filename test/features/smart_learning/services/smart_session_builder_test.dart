import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/models/option.dart' as model;
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_session_builder.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/smart_utils.dart';

List<Question> makeQuestions(int count) => List.generate(
      count,
      (i) => Question(
        questionId: 'q$i',
        text: 'Question $i',
        options: [
          model.Option(optionLabel: 'A', text: 'Answer A', imageUrl: '')
        ],
        correctAnswer: 'A',
        answerExplanation: '',
        imageUrl: '',
        images: const [],
        tabs: const [],
      ),
    );

void main() {
  final questions = makeQuestions(70);
  final sizes = SmartUtils.computeSmartSizes(70); // [14,14,14,14,14]

  group('SmartSessionBuilder.build', () {
    test('base slice has correct size for chunk 0', () {
      final session = SmartSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 0,
        weakQuestionIds: [],
      );
      expect(session.length, 14);
    });

    test('base slice contains correct questions for chunk 1', () {
      final session = SmartSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 1,
        weakQuestionIds: [],
      );
      final ids = session.map((q) => q.questionId).toSet();
      for (var i = 14; i < 28; i++) {
        expect(ids, contains('q$i'));
      }
    });

    test('injects weak questions capped at 30% of chunkSize', () {
      final weakIds = ['q50', 'q51', 'q52', 'q53', 'q54', 'q55'];
      final session = SmartSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 0,
        weakQuestionIds: weakIds,
      );
      // cap = floor(14 * 0.3) = 4
      final injected =
          session.where((q) => weakIds.contains(q.questionId)).length;
      expect(injected, 4);
      expect(session.length, 18); // 14 base + 4 weak
    });

    test('does not inject weak questions already in base slice', () {
      // q0..q13 are in chunk 0 base
      final session = SmartSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 0,
        weakQuestionIds: ['q0', 'q1', 'q50', 'q51'],
      );
      final ids = session.map((q) => q.questionId).toList();
      expect(ids.where((id) => id == 'q0').length, 1);
      expect(ids.where((id) => id == 'q1').length, 1);
    });

    test('same base questions on retry (same chunkIndex)', () {
      final s1 = SmartSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 2,
        weakQuestionIds: [],
      );
      final s2 = SmartSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 2,
        weakQuestionIds: [],
      );
      expect(s1.map((q) => q.questionId).toSet(),
          equals(s2.map((q) => q.questionId).toSet()));
    });
  });

  group('SmartQueueManager', () {
    test('isDone false on start, true after all answered', () {
      final mgr = SmartQueueManager(makeQuestions(3));
      expect(mgr.isDone, false);
      mgr.answer(true);
      mgr.answer(true);
      mgr.answer(true);
      expect(mgr.isDone, true);
    });

    test('score counts first-attempt correct only', () {
      // Drive manager to completion, answering q0/q2 correctly and q1/q3 wrongly.
      // Re-ask order is random, so we identify questions by ID not position.
      final correctIds = {'q0', 'q2'};
      final mgr = SmartQueueManager(makeQuestions(4));
      int safety = 0;
      while (!mgr.isDone && safety < 20) {
        mgr.answer(correctIds.contains(mgr.current.questionId));
        safety++;
      }
      // 2 of 4 first attempts correct → 0.5
      expect(mgr.score, closeTo(0.5, 0.001));
    });

    test('wrong answer adds exactly one extra question to the session', () {
      // No wrong answers: 3 questions total
      final mgrClean = SmartQueueManager(makeQuestions(3));
      int count = 0;
      while (!mgrClean.isDone) {
        mgrClean.answer(true);
        count++;
      }
      expect(count, 3);

      // One wrong answer: 3 + 1 re-ask = 4
      final mgr = SmartQueueManager(makeQuestions(3));
      int count2 = 0;
      bool didWrong = false;
      while (!mgr.isDone) {
        if (!didWrong) {
          mgr.answer(false);
          didWrong = true;
        } else {
          mgr.answer(true);
        }
        count2++;
        if (count2 > 10) break; // safety
      }
      expect(count2, 4);
    });

    test('question re-asked at most once per session', () {
      final mgr = SmartQueueManager(makeQuestions(2));
      mgr.answer(false); // q0 wrong -> re-inserted
      mgr.answer(false); // q1 wrong -> re-inserted
      mgr.answer(false); // q0 re-ask wrong -> NOT re-inserted again
      mgr.answer(false); // q1 re-ask wrong
      expect(mgr.isDone, true);
    });

    test('firstAttempts records only first answer', () {
      final mgr = SmartQueueManager(makeQuestions(2));
      mgr.answer(false); // q0 wrong first attempt
      mgr.answer(true); // q1 correct
      mgr.answer(true); // q0 re-ask correct -- must NOT overwrite firstAttempts
      expect(mgr.firstAttempts['q0'], false);
      expect(mgr.firstAttempts['q1'], true);
    });
  });
}
