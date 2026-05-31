import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/smart_learning/models/smart_progress.dart';
import 'package:taxi_exam_app/features/smart_learning/models/weak_question.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_progress_service.dart';

// We access chunkProgressBox/weakQuestionsBox via the service which internally
// calls AppStorage. For tests we init Hive manually and open the boxes directly.
import 'package:hive/hive.dart' as hive_lib;

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('smart_learn_test_');
    hive_lib.Hive.init(tempDir.path);
    if (!hive_lib.Hive.isAdapterRegistered(6)) {
      hive_lib.Hive.registerAdapter(SmartProgressAdapter());
    }
    if (!hive_lib.Hive.isAdapterRegistered(7)) {
      hive_lib.Hive.registerAdapter(WeakQuestionAdapter());
    }
  });

  tearDownAll(() async {
    await hive_lib.Hive.close();
    await tempDir.delete(recursive: true);
  });

  tearDown(() async {
    if (hive_lib.Hive.isBoxOpen('chunkProgress')) {
      await hive_lib.Hive.box<SmartProgress>('chunkProgress').clear();
    }
    if (hive_lib.Hive.isBoxOpen('weakQuestions')) {
      await hive_lib.Hive.box<WeakQuestion>('weakQuestions').clear();
    }
  });

  // Pre-open boxes before tests run (AppStorage opens lazily; in tests we
  // need them open so AppStorage._openBox returns the already-open box).
  setUpAll(() async {
    await hive_lib.Hive.openBox<SmartProgress>('chunkProgress');
    await hive_lib.Hive.openBox<WeakQuestion>('weakQuestions');
  });

  final svc = SmartProgressService();

  group('activeChunkIndex', () {
    test('returns 0 when no progress', () async {
      expect(await svc.activeSmartIndex(100, 5), 0);
    });

    test('returns 1 after chunk 0 passed', () async {
      await svc.recordSmartResult(100, 0, true);
      expect(await svc.activeSmartIndex(100, 5), 1);
    });

    test('returns 0 after chunk 0 failed', () async {
      await svc.recordSmartResult(100, 0, false);
      expect(await svc.activeSmartIndex(100, 5), 0);
    });

    test('returns totalChunks when all passed', () async {
      await svc.recordSmartResult(100, 0, true);
      await svc.recordSmartResult(100, 1, true);
      expect(await svc.activeSmartIndex(100, 2), 2);
    });
  });

  group('isFullExamUnlocked', () {
    test('false when no progress', () async {
      expect(await svc.isFullExamUnlocked(200, 3), false);
    });

    test('true when all chunks passed', () async {
      await svc.recordSmartResult(200, 0, true);
      await svc.recordSmartResult(200, 1, true);
      await svc.recordSmartResult(200, 2, true);
      expect(await svc.isFullExamUnlocked(200, 3), true);
    });
  });

  group('recordSessionResults — weak pool', () {
    test('wrong answer creates weak entry', () async {
      await svc.recordSessionResults(300, {'q1': false});
      final ids = await svc.allWeakQuestionIds(300);
      expect(ids, contains('q1'));
    });

    test('correct answer on first encounter does not create entry', () async {
      await svc.recordSessionResults(300, {'q2': true});
      final ids = await svc.allWeakQuestionIds(300);
      expect(ids, isNot(contains('q2')));
    });

    test('graduates after 2 consecutive correct answers', () async {
      await svc.recordSessionResults(300, {'q3': false});
      await svc.recordSessionResults(300, {'q3': true});
      await svc.recordSessionResults(300, {'q3': true});
      final ids = await svc.allWeakQuestionIds(300);
      expect(ids, isNot(contains('q3')));
    });

    test('wrong answer resets streak; two new correct answers graduate',
        () async {
      await svc.recordSessionResults(400, {'q4': false});
      await svc.recordSessionResults(400, {'q4': true});
      await svc.recordSessionResults(400, {'q4': true});

      // Re-introduce after graduation and verify reset path.
      await svc.recordSessionResults(400, {'q4': false});
      await svc.recordSessionResults(400, {'q4': true});
      await svc.recordSessionResults(400, {'q4': true});

      final ids = await svc.allWeakQuestionIds(400);
      expect(ids, isNot(contains('q4')));
    });
  });

  group('weakQuestionIdsFor', () {
    test('caps at 30% of chunkSize', () async {
      final results = {for (var i = 0; i < 10; i++) 'q$i': false};
      await svc.recordSessionResults(500, results);
      // chunkSize = 14 → cap = floor(14 * 0.3) = 4
      final ids = await svc.weakQuestionIdsFor(500, 14);
      expect(ids.length, lessThanOrEqualTo(4));
    });
  });
}
