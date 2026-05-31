# Smart Learning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional Smart Learning mode that trains users chunk-by-chunk, tracks weak questions, and unlocks the full exam only after all chunks are passed — without touching any existing screen.

**Architecture:** Fully client-side. Auto-chunking algorithm splits any exam into equal slices. Wrong answers are tracked in Hive and injected into future sessions. All new code lives under `lib/features/smart_learning/`; the only modification to existing files is adding a card on the home screen and two box accessors on `AppStorage`.

**Tech Stack:** Flutter, Hive (typeIds 6 & 7), `BcdCache` (existing singleton), `BcdProvider` (existing singleton), slang localization, `Theme.of(context)` for all colors/styles.

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `lib/features/smart_learning/models/chunk_progress.dart` | Create | Hive model typeId 6 |
| `lib/features/smart_learning/models/chunk_progress.g.dart` | Create | Hand-written Hive adapter |
| `lib/features/smart_learning/models/weak_question.dart` | Create | Hive model typeId 7 |
| `lib/features/smart_learning/models/weak_question.g.dart` | Create | Hand-written Hive adapter |
| `lib/features/smart_learning/utils/chunk_utils.dart` | Create | Auto-chunk algorithm |
| `lib/features/smart_learning/services/chunk_progress_service.dart` | Create | Read/write chunk progress + weak pool |
| `lib/features/smart_learning/services/chunk_session_builder.dart` | Create | Builds question queue for a session |
| `lib/features/smart_learning/smart_learning_screen.dart` | Create | Exam list with progress |
| `lib/features/smart_learning/bcd_chunk_list_screen.dart` | Create | Chunk map for one exam |
| `lib/features/smart_learning/chunk_test_screen.dart` | Create | Standalone chunk session runner |
| `lib/core/storage/app_storage.dart` | Modify | Add `chunkProgressBox()` + `weakQuestionsBox()` |
| `lib/main.dart` | Modify | Register adapters typeId 6 & 7 |
| `lib/core/localization/strings.i18n.json` | Modify | Add `smart_*` translation keys |
| `lib/core/localization/strings_sv.i18n.json` | Modify | Swedish translations |
| `lib/core/localization/strings_en.g.dart` | Modify | Generated EN class |
| `lib/core/localization/strings_sv.g.dart` | Modify | Generated SV class |
| `lib/core/localization/strings.g.dart` | Modify | Add keys to base `Translations` class |
| `lib/features/home/home_screen.dart` | Modify | Add Smart Learning card |
| `test/features/smart_learning/chunk_utils_test.dart` | Create | Unit tests for algorithm |
| `test/features/smart_learning/chunk_queue_manager_test.dart` | Create | Unit tests for queue manager |
| `test/features/smart_learning/chunk_session_builder_test.dart` | Create | Unit tests for session builder |
| `test/features/smart_learning/chunk_progress_service_test.dart` | Create | Integration tests with real Hive |

---

## Task 1: Hive Models

**Files:**
- Create: `lib/features/smart_learning/models/chunk_progress.dart`
- Create: `lib/features/smart_learning/models/chunk_progress.g.dart`
- Create: `lib/features/smart_learning/models/weak_question.dart`
- Create: `lib/features/smart_learning/models/weak_question.g.dart`

- [ ] **Step 1: Create the models directory and `chunk_progress.dart`**

```dart
// lib/features/smart_learning/models/chunk_progress.dart
import 'package:hive/hive.dart';

part 'chunk_progress.g.dart';

@HiveType(typeId: 6)
class ChunkProgress extends HiveObject {
  @HiveField(0)
  final int testBcdId;

  @HiveField(1)
  final int chunkIndex;

  @HiveField(2)
  final bool isPassed;

  @HiveField(3)
  final DateTime completedAt;

  ChunkProgress({
    required this.testBcdId,
    required this.chunkIndex,
    required this.isPassed,
    required this.completedAt,
  });
}
```

- [ ] **Step 2: Create `chunk_progress.g.dart`**

```dart
// lib/features/smart_learning/models/chunk_progress.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'chunk_progress.dart';

class ChunkProgressAdapter extends TypeAdapter<ChunkProgress> {
  @override
  final int typeId = 6;

  @override
  ChunkProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChunkProgress(
      testBcdId: fields[0] as int,
      chunkIndex: fields[1] as int,
      isPassed: fields[2] as bool,
      completedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChunkProgress obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.testBcdId)
      ..writeByte(1)
      ..write(obj.chunkIndex)
      ..writeByte(2)
      ..write(obj.isPassed)
      ..writeByte(3)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChunkProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
```

- [ ] **Step 3: Create `weak_question.dart`**

```dart
// lib/features/smart_learning/models/weak_question.dart
import 'package:hive/hive.dart';

part 'weak_question.g.dart';

@HiveType(typeId: 7)
class WeakQuestion extends HiveObject {
  @HiveField(0)
  final int testBcdId;

  @HiveField(1)
  final String questionId;

  @HiveField(2)
  int wrongCount;

  @HiveField(3)
  int correctStreak;

  @HiveField(4)
  DateTime lastSeen;

  WeakQuestion({
    required this.testBcdId,
    required this.questionId,
    this.wrongCount = 0,
    this.correctStreak = 0,
    required this.lastSeen,
  });
}
```

- [ ] **Step 4: Create `weak_question.g.dart`**

```dart
// lib/features/smart_learning/models/weak_question.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'weak_question.dart';

class WeakQuestionAdapter extends TypeAdapter<WeakQuestion> {
  @override
  final int typeId = 7;

  @override
  WeakQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeakQuestion(
      testBcdId: fields[0] as int,
      questionId: fields[1] as String,
      wrongCount: fields[2] as int,
      correctStreak: fields[3] as int,
      lastSeen: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WeakQuestion obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.testBcdId)
      ..writeByte(1)
      ..write(obj.questionId)
      ..writeByte(2)
      ..write(obj.wrongCount)
      ..writeByte(3)
      ..write(obj.correctStreak)
      ..writeByte(4)
      ..write(obj.lastSeen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeakQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
```

---

## Task 2: Register Adapters + Add Box Accessors

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/core/storage/app_storage.dart`

- [ ] **Step 1: Register adapters in `main.dart`**

Find the block that starts at line 128 (`if (!Hive.isAdapterRegistered(0))`). Add after the line registering `ExamNodeAdapter` (typeId 5):

```dart
if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(ChunkProgressAdapter());
if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(WeakQuestionAdapter());
```

Also add imports at the top of `main.dart`:
```dart
import 'package:taxi_exam_app/features/smart_learning/models/chunk_progress.dart';
import 'package:taxi_exam_app/features/smart_learning/models/weak_question.dart';
```

- [ ] **Step 2: Add box accessors to `AppStorage`**

Add two constants and two accessors following the existing pattern. Add after `static const String kReceipts = 'purchase_receipts';`:

```dart
static const String kChunkProgress = 'chunkProgress';
static const String kWeakQuestions = 'weakQuestions';
```

Add after `receiptsBox()`:

```dart
/// Chunk learning progress box — NOT user-scoped (progress persists across
/// logins on the same device intentionally).
static Future<Box<ChunkProgress>> chunkProgressBox() =>
    _openBox<ChunkProgress>(kChunkProgress);

/// Weak question pool — NOT user-scoped (same reasoning as chunk progress).
static Future<Box<WeakQuestion>> weakQuestionsBox() =>
    _openBox<WeakQuestion>(kWeakQuestions);
```

Add imports at top of `app_storage.dart`:
```dart
import 'package:taxi_exam_app/features/smart_learning/models/chunk_progress.dart';
import 'package:taxi_exam_app/features/smart_learning/models/weak_question.dart';
```

- [ ] **Step 3: Verify the app compiles with no errors**

```bash
cd /Users/muhammadmohsin/Documents/Learning/TAXI/App/taxi_exam_app
flutter analyze lib/core/storage/app_storage.dart lib/main.dart
```

Expected: `No issues found!`

---

## Task 3: ChunkUtils + Tests

**Files:**
- Create: `lib/features/smart_learning/utils/chunk_utils.dart`
- Create: `test/features/smart_learning/chunk_utils_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/smart_learning/chunk_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/chunk_utils.dart';

void main() {
  group('ChunkUtils.computeChunkSizes', () {
    test('10 questions — no split', () {
      expect(ChunkUtils.computeChunkSizes(10), [10]);
    });

    test('9 questions — no split', () {
      expect(ChunkUtils.computeChunkSizes(9), [9]);
    });

    test('15 questions → [8, 7]', () {
      expect(ChunkUtils.computeChunkSizes(15), [8, 7]);
    });

    test('20 questions → [10, 10]', () {
      expect(ChunkUtils.computeChunkSizes(20), [10, 10]);
    });

    test('25 questions → [13, 12]', () {
      expect(ChunkUtils.computeChunkSizes(25), [13, 12]);
    });

    test('40 questions → [14, 13, 13]', () {
      expect(ChunkUtils.computeChunkSizes(40), [14, 13, 13]);
    });

    test('70 questions → 5 chunks of 14', () {
      expect(ChunkUtils.computeChunkSizes(70), [14, 14, 14, 14, 14]);
    });

    test('65 questions → 5 chunks of 13', () {
      expect(ChunkUtils.computeChunkSizes(65), [13, 13, 13, 13, 13]);
    });

    test('total of sizes equals input', () {
      for (final n in [11, 20, 25, 30, 45, 60, 70, 80]) {
        final sizes = ChunkUtils.computeChunkSizes(n);
        expect(sizes.fold(0, (a, b) => a + b), n,
            reason: 'sizes must sum to $n');
      }
    });
  });

  group('ChunkUtils.chunkOffset', () {
    test('offset 0 is always 0', () {
      expect(ChunkUtils.chunkOffset([8, 7], 0), 0);
    });

    test('offset 1 equals first chunk size', () {
      expect(ChunkUtils.chunkOffset([8, 7], 1), 8);
    });

    test('offset 2 equals sum of first two', () {
      expect(ChunkUtils.chunkOffset([14, 14, 14, 14, 14], 2), 28);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/features/smart_learning/chunk_utils_test.dart
```

Expected: `Error: Could not find package 'taxi_exam_app/features/smart_learning/utils/chunk_utils.dart'`

- [ ] **Step 3: Create `chunk_utils.dart`**

```dart
// lib/features/smart_learning/utils/chunk_utils.dart
class ChunkUtils {
  ChunkUtils._();

  /// Returns sizes of each chunk. Single-element list = no chunking.
  ///
  /// Rules:
  ///   total <= 10  → [total]       (no split)
  ///   total <= 25  → target = 10
  ///   total >  25  → target = 15
  ///
  /// Remainder distributed one-per-chunk from the front.
  static List<int> computeChunkSizes(int total) {
    if (total <= 10) return [total];
    final targetSize = total <= 25 ? 10 : 15;
    final count = (total / targetSize).ceil();
    final base = total ~/ count;
    final remainder = total % count;
    return List.generate(count, (i) => base + (i < remainder ? 1 : 0));
  }

  /// Returns the start index in the full question list for [chunkIndex].
  static int chunkOffset(List<int> sizes, int chunkIndex) =>
      sizes.take(chunkIndex).fold(0, (a, b) => a + b);
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/features/smart_learning/chunk_utils_test.dart
```

Expected: `All tests passed!`

---

## Task 4: ChunkProgressService + Tests

**Files:**
- Create: `lib/features/smart_learning/services/chunk_progress_service.dart`
- Create: `test/features/smart_learning/chunk_progress_service_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/features/smart_learning/chunk_progress_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/features/smart_learning/models/chunk_progress.dart';
import 'package:taxi_exam_app/features/smart_learning/models/weak_question.dart';
import 'package:taxi_exam_app/features/smart_learning/services/chunk_progress_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(ChunkProgressAdapter());
    Hive.registerAdapter(WeakQuestionAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('chunkProgress');
    await Hive.deleteBoxFromDisk('weakQuestions');
  });

  final svc = ChunkProgressService();

  group('activeChunkIndex', () {
    test('returns 0 when no progress', () async {
      expect(await svc.activeChunkIndex(100, 5), 0);
    });

    test('returns 1 after chunk 0 passed', () async {
      await svc.recordChunkResult(100, 0, true);
      expect(await svc.activeChunkIndex(100, 5), 1);
    });

    test('returns 0 after chunk 0 failed', () async {
      await svc.recordChunkResult(100, 0, false);
      expect(await svc.activeChunkIndex(100, 5), 0);
    });

    test('returns totalChunks when all passed', () async {
      await svc.recordChunkResult(100, 0, true);
      await svc.recordChunkResult(100, 1, true);
      expect(await svc.activeChunkIndex(100, 2), 2);
    });
  });

  group('isFullExamUnlocked', () {
    test('false when no progress', () async {
      expect(await svc.isFullExamUnlocked(200, 3), false);
    });

    test('true when all chunks passed', () async {
      await svc.recordChunkResult(200, 0, true);
      await svc.recordChunkResult(200, 1, true);
      await svc.recordChunkResult(200, 2, true);
      expect(await svc.isFullExamUnlocked(200, 3), true);
    });
  });

  group('recordSessionResults — weak pool', () {
    test('wrong answer creates weak entry', () async {
      await svc.recordSessionResults(300, {'q1': false});
      final ids = await svc.allWeakQuestionIds(300);
      expect(ids, contains('q1'));
    });

    test('correct answer does not create entry', () async {
      await svc.recordSessionResults(300, {'q2': true});
      final ids = await svc.allWeakQuestionIds(300);
      expect(ids, isNot(contains('q2')));
    });

    test('wrong 3× then correct 3× graduates the question', () async {
      // Make it weak
      await svc.recordSessionResults(300, {'q3': false});
      await svc.recordSessionResults(300, {'q3': false});
      await svc.recordSessionResults(300, {'q3': false});
      // Build streak
      await svc.recordSessionResults(300, {'q3': true});
      await svc.recordSessionResults(300, {'q3': true});
      await svc.recordSessionResults(300, {'q3': true});
      final ids = await svc.allWeakQuestionIds(300);
      expect(ids, isNot(contains('q3')));
    });

    test('wrong answer resets streak', () async {
      await svc.recordSessionResults(400, {'q4': false});
      await svc.recordSessionResults(400, {'q4': true});
      await svc.recordSessionResults(400, {'q4': true});
      // Streak is now 2 — wrong resets it
      await svc.recordSessionResults(400, {'q4': false});
      await svc.recordSessionResults(400, {'q4': true});
      await svc.recordSessionResults(400, {'q4': true});
      // Streak is 2 again — not yet graduated
      final ids = await svc.allWeakQuestionIds(400);
      expect(ids, contains('q4'));
    });
  });

  group('weakQuestionIdsFor', () {
    test('caps at 30% of chunkSize', () async {
      // Add 10 weak questions
      final results = {for (var i = 0; i < 10; i++) 'q$i': false};
      await svc.recordSessionResults(500, results);
      // chunkSize = 14 → cap = floor(14 * 0.3) = 4
      final ids = await svc.weakQuestionIdsFor(500, 14);
      expect(ids.length, lessThanOrEqualTo(4));
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/features/smart_learning/chunk_progress_service_test.dart
```

Expected: compile error (service not yet created)

- [ ] **Step 3: Create `chunk_progress_service.dart`**

```dart
// lib/features/smart_learning/services/chunk_progress_service.dart
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/features/smart_learning/models/chunk_progress.dart';
import 'package:taxi_exam_app/features/smart_learning/models/weak_question.dart';

class ChunkProgressService {
  static final ChunkProgressService _instance = ChunkProgressService._();
  factory ChunkProgressService() => _instance;
  ChunkProgressService._();

  String _chunkKey(int testBcdId, int chunkIndex) => '$testBcdId-$chunkIndex';
  String _weakKey(int testBcdId, String questionId) => '$testBcdId-$questionId';

  /// Returns the 0-based index of the first unpassed chunk.
  /// Returns [totalChunks] when all are passed.
  Future<int> activeChunkIndex(int testBcdId, int totalChunks) async {
    final box = await AppStorage.chunkProgressBox();
    for (var i = 0; i < totalChunks; i++) {
      final entry = box.get(_chunkKey(testBcdId, i));
      if (entry == null || !entry.isPassed) return i;
    }
    return totalChunks;
  }

  /// True when all [totalChunks] chunks have isPassed = true.
  Future<bool> isFullExamUnlocked(int testBcdId, int totalChunks) async {
    return await activeChunkIndex(testBcdId, totalChunks) >= totalChunks;
  }

  /// Persists pass/fail for one chunk attempt.
  Future<void> recordChunkResult(
      int testBcdId, int chunkIndex, bool passed) async {
    final box = await AppStorage.chunkProgressBox();
    await box.put(
      _chunkKey(testBcdId, chunkIndex),
      ChunkProgress(
        testBcdId: testBcdId,
        chunkIndex: chunkIndex,
        isPassed: passed,
        completedAt: DateTime.now(),
      ),
    );
  }

  /// Updates the weak pool from first-attempt results.
  ///
  /// [questionResults]: Map<questionId, wasCorrect>
  /// - Wrong → wrongCount++, correctStreak = 0
  /// - Correct → correctStreak++; if >= 3 → graduated (entry deleted)
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
          if (existing.correctStreak >= 3) {
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
  Future<List<String>> weakQuestionIdsFor(
      int testBcdId, int chunkSize) async {
    final box = await AppStorage.weakQuestionsBox();
    final cap = (chunkSize * 0.3).floor();
    final weak = box.values
        .where((wq) => wq.testBcdId == testBcdId)
        .toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return weak.take(cap).map((wq) => wq.questionId).toList();
  }

  /// Returns all weak question IDs for [testBcdId] (for Train Mistakes mode).
  Future<List<String>> allWeakQuestionIds(int testBcdId) async {
    final box = await AppStorage.weakQuestionsBox();
    final weak = box.values
        .where((wq) => wq.testBcdId == testBcdId)
        .toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return weak.map((wq) => wq.questionId).toList();
  }

  /// Total count of weak questions for [testBcdId]. Sync if box already open.
  Future<int> weakQuestionCount(int testBcdId) async {
    final box = await AppStorage.weakQuestionsBox();
    return box.values.where((wq) => wq.testBcdId == testBcdId).length;
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/features/smart_learning/chunk_progress_service_test.dart
```

Expected: `All tests passed!`

---

## Task 5: ChunkSessionBuilder + ChunkQueueManager + Tests

**Files:**
- Create: `lib/features/smart_learning/services/chunk_session_builder.dart`
- Create: `test/features/smart_learning/chunk_session_builder_test.dart`
- Create: `test/features/smart_learning/chunk_queue_manager_test.dart`

- [ ] **Step 1: Write failing tests for ChunkSessionBuilder**

```dart
// test/features/smart_learning/chunk_session_builder_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/smart_learning/services/chunk_session_builder.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/chunk_utils.dart';

List<Question> _makeQuestions(int count) => List.generate(
      count,
      (i) => Question(
        questionId: 'q$i',
        text: 'Question $i',
        options: [Option(optionLabel: 'A', text: 'A', imageUrl: '')],
        correctAnswer: 'A',
        answerExplanation: '',
        imageUrl: '',
        images: const [],
        tabs: const [],
      ),
    );

void main() {
  final questions = _makeQuestions(70);
  final sizes = ChunkUtils.computeChunkSizes(70); // [14,14,14,14,14]

  group('ChunkSessionBuilder.build', () {
    test('base slice has correct size for chunk 0', () {
      final session = ChunkSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 0,
        weakQuestionIds: [],
      );
      // 14 base + 0 weak
      expect(session.length, 14);
    });

    test('base slice contains correct questions for chunk 1', () {
      final session = ChunkSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 1,
        weakQuestionIds: [],
      );
      final ids = session.map((q) => q.questionId).toSet();
      // Chunk 1 = questions 14..27 (q14..q27)
      for (var i = 14; i < 28; i++) {
        expect(ids, contains('q$i'));
      }
    });

    test('injects weak questions (capped at 30% of chunkSize)', () {
      final weakIds = ['q50', 'q51', 'q52', 'q53', 'q54', 'q55'];
      final session = ChunkSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 0,
        weakQuestionIds: weakIds,
      );
      // cap = floor(14 * 0.3) = 4
      final injected = session
          .where((q) => weakIds.contains(q.questionId))
          .length;
      expect(injected, 4);
      expect(session.length, 18); // 14 base + 4 weak
    });

    test('does not inject weak questions already in base slice', () {
      // q0..q13 are in chunk 0's base
      final session = ChunkSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 0,
        weakQuestionIds: ['q0', 'q1', 'q50', 'q51'],
      );
      final ids = session.map((q) => q.questionId).toList();
      // q0 and q1 are already in base — should not appear twice
      expect(ids.where((id) => id == 'q0').length, 1);
      expect(ids.where((id) => id == 'q1').length, 1);
    });

    test('same base questions on retry (same chunkIndex)', () {
      final session1 = ChunkSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 2,
        weakQuestionIds: [],
      );
      final session2 = ChunkSessionBuilder.build(
        allQuestions: questions,
        chunkSizes: sizes,
        chunkIndex: 2,
        weakQuestionIds: [],
      );
      // Base IDs must be identical regardless of shuffle
      final ids1 = session1.map((q) => q.questionId).toSet();
      final ids2 = session2.map((q) => q.questionId).toSet();
      expect(ids1, equals(ids2));
    });
  });
}
```

- [ ] **Step 2: Write failing tests for ChunkQueueManager**

```dart
// test/features/smart_learning/chunk_queue_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/smart_learning/services/chunk_session_builder.dart';

List<Question> _makeQ(int count) => List.generate(
      count,
      (i) => Question(
        questionId: 'q$i',
        text: 'Q$i',
        options: [Option(optionLabel: 'A', text: 'A', imageUrl: '')],
        correctAnswer: 'A',
        answerExplanation: '',
        imageUrl: '',
        images: const [],
        tabs: const [],
      ),
    );

void main() {
  group('ChunkQueueManager', () {
    test('isDone is false on start, true after all answered', () {
      final mgr = ChunkQueueManager(_makeQ(3));
      expect(mgr.isDone, false);
      mgr.answer(true);
      mgr.answer(true);
      mgr.answer(true);
      expect(mgr.isDone, true);
    });

    test('score counts first-attempt correct answers only', () {
      final mgr = ChunkQueueManager(_makeQ(4));
      mgr.answer(true);  // q0 correct
      mgr.answer(false); // q1 wrong → re-inserted
      mgr.answer(true);  // q2 correct
      mgr.answer(false); // q3 wrong → re-inserted
      // Re-asks now appear
      mgr.answer(true);  // q1 re-ask: correct
      mgr.answer(true);  // q3 re-ask: correct
      // First attempts: 2/4 correct
      expect(mgr.score, closeTo(0.5, 0.001));
    });

    test('wrong answer re-inserts question after current position', () {
      final mgr = ChunkQueueManager(_makeQ(3));
      final firstId = mgr.current.questionId;
      mgr.answer(false); // wrong → re-inserted
      // advance through remaining
      mgr.answer(true);
      mgr.answer(true);
      // one more should appear (the re-ask)
      expect(mgr.isDone, false);
      expect(mgr.current.questionId, firstId);
    });

    test('question re-asked at most once', () {
      final mgr = ChunkQueueManager(_makeQ(2));
      mgr.answer(false); // q0 wrong → re-inserted once
      mgr.answer(false); // q1 wrong → re-inserted once
      mgr.answer(false); // q0 re-ask wrong → NOT re-inserted again
      mgr.answer(false); // q1 re-ask wrong → NOT re-inserted again
      expect(mgr.isDone, true);
    });

    test('firstAttempts contains only first answers', () {
      final mgr = ChunkQueueManager(_makeQ(2));
      mgr.answer(false); // q0 wrong first attempt
      mgr.answer(true);  // q1 correct first attempt
      mgr.answer(true);  // q0 re-ask correct — should NOT overwrite firstAttempts
      expect(mgr.firstAttempts['q0'], false);
      expect(mgr.firstAttempts['q1'], true);
    });
  });
}
```

- [ ] **Step 3: Run tests — expect failure**

```bash
flutter test test/features/smart_learning/chunk_session_builder_test.dart test/features/smart_learning/chunk_queue_manager_test.dart
```

Expected: compile errors

- [ ] **Step 4: Create `chunk_session_builder.dart`**

```dart
// lib/features/smart_learning/services/chunk_session_builder.dart
import 'dart:math';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/chunk_utils.dart';

class ChunkSessionBuilder {
  ChunkSessionBuilder._();

  /// Builds the question list for one chunk session.
  ///
  /// Base questions are the same every retry for [chunkIndex].
  /// Weak questions are injected (capped at 30% of chunk size),
  /// excluding any already in the base slice.
  static List<Question> build({
    required List<Question> allQuestions,
    required List<int> chunkSizes,
    required int chunkIndex,
    required List<String> weakQuestionIds,
  }) {
    final offset = ChunkUtils.chunkOffset(chunkSizes, chunkIndex);
    final size = chunkSizes[chunkIndex];
    final base = allQuestions.sublist(offset, offset + size);

    final baseIds = base.map((q) => q.questionId).toSet();
    final cap = (size * 0.3).floor();
    final weak = weakQuestionIds
        .where((id) => !baseIds.contains(id))
        .take(cap)
        .map((id) => allQuestions.firstWhere((q) => q.questionId == id))
        .toList();

    return [...base, ...weak]..shuffle(Random());
  }
}

/// Manages the mutable question queue for a single chunk session.
///
/// Wrong answers are silently re-inserted once at a random later position.
/// Score is based on first attempts only.
class ChunkQueueManager {
  final List<Question> _queue;
  final Set<String> _reAsked = {};
  int _cursor = 0;
  final Map<String, bool> _firstAttempts = {};

  ChunkQueueManager(List<Question> questions)
      : _queue = List<Question>.from(questions);

  bool get isDone => _cursor >= _queue.length;

  Question get current => _queue[_cursor];

  Map<String, bool> get firstAttempts => Map.unmodifiable(_firstAttempts);

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
```

- [ ] **Step 5: Run tests — expect pass**

```bash
flutter test test/features/smart_learning/chunk_session_builder_test.dart test/features/smart_learning/chunk_queue_manager_test.dart
```

Expected: `All tests passed!`

---

## Task 6: Translation Keys

**Files:**
- Modify: `lib/core/localization/strings.i18n.json`
- Modify: `lib/core/localization/strings_sv.i18n.json`
- Modify: `lib/core/localization/strings_en.g.dart`
- Modify: `lib/core/localization/strings_sv.g.dart`
- Modify: `lib/core/localization/strings.g.dart`

- [ ] **Step 1: Add keys to `strings.i18n.json`**

Add these entries inside the root JSON object (before the closing `}`):

```json
"smart_learning_title": "Smart Learning",
"smart_learning_subtitle": "Train chunk by chunk, master your weak spots",
"smart_chunk_label": "Smart Learning",
"smart_chunk_n": "Part {n}",
"smart_chunk_passed": "Passed",
"smart_chunk_locked": "Locked",
"smart_chunk_active": "Start",
"smart_chunk_retry": "Retry",
"smart_full_exam": "Full Exam",
"smart_full_exam_locked": "Complete all parts to unlock",
"smart_full_exam_ready": "Full exam ready",
"smart_train_mistakes": "Train Mistakes ({count})",
"smart_practice_mode": "Practice",
"smart_timed_mode": "Timed Exam",
"smart_not_started": "Not started",
"smart_chunks_done": "{done} of {total} parts done",
"smart_result_passed": "Part passed!",
"smart_result_failed": "Not quite — try again",
"smart_result_weak_updated": "{count} weak questions updated",
"smart_result_continue": "Continue",
"smart_no_exams": "No exams available for Smart Learning yet"
```

- [ ] **Step 2: Add keys to `strings_sv.i18n.json`**

```json
"smart_learning_title": "Smart Learning",
"smart_learning_subtitle": "Träna del för del, bemästra dina svaga punkter",
"smart_chunk_label": "Smart Learning",
"smart_chunk_n": "Del {n}",
"smart_chunk_passed": "Godkänd",
"smart_chunk_locked": "Låst",
"smart_chunk_active": "Starta",
"smart_chunk_retry": "Försök igen",
"smart_full_exam": "Fullständigt prov",
"smart_full_exam_locked": "Slutför alla delar för att låsa upp",
"smart_full_exam_ready": "Fullständigt prov redo",
"smart_train_mistakes": "Träna misstag ({count})",
"smart_practice_mode": "Övning",
"smart_timed_mode": "Tidsbegränsat prov",
"smart_not_started": "Ej påbörjad",
"smart_chunks_done": "{done} av {total} delar klara",
"smart_result_passed": "Del godkänd!",
"smart_result_failed": "Inte riktigt — försök igen",
"smart_result_weak_updated": "{count} svaga frågor uppdaterade",
"smart_result_continue": "Fortsätt",
"smart_no_exams": "Inga prov tillgängliga för Smart Learning ännu"
```

- [ ] **Step 3: Add keys to `strings.g.dart` (base `Translations` abstract class)**

Open `strings.g.dart`. Find the abstract `Translations` class. Add after the last existing string getter:

```dart
String get smart_learning_title;
String get smart_learning_subtitle;
String get smart_chunk_label;
String smart_chunk_n({required int n});
String get smart_chunk_passed;
String get smart_chunk_locked;
String get smart_chunk_active;
String get smart_chunk_retry;
String get smart_full_exam;
String get smart_full_exam_locked;
String get smart_full_exam_ready;
String smart_train_mistakes({required int count});
String get smart_practice_mode;
String get smart_timed_mode;
String get smart_not_started;
String smart_chunks_done({required int done, required int total});
String get smart_result_passed;
String get smart_result_failed;
String smart_result_weak_updated({required int count});
String get smart_result_continue;
String get smart_no_exams;
```

- [ ] **Step 4: Add implementations to `strings_en.g.dart`**

Find the `TranslationsEn` class. Add:

```dart
@override String get smart_learning_title => 'Smart Learning';
@override String get smart_learning_subtitle => 'Train chunk by chunk, master your weak spots';
@override String get smart_chunk_label => 'Smart Learning';
@override String smart_chunk_n({required int n}) => 'Part $n';
@override String get smart_chunk_passed => 'Passed';
@override String get smart_chunk_locked => 'Locked';
@override String get smart_chunk_active => 'Start';
@override String get smart_chunk_retry => 'Retry';
@override String get smart_full_exam => 'Full Exam';
@override String get smart_full_exam_locked => 'Complete all parts to unlock';
@override String get smart_full_exam_ready => 'Full exam ready';
@override String smart_train_mistakes({required int count}) => 'Train Mistakes ($count)';
@override String get smart_practice_mode => 'Practice';
@override String get smart_timed_mode => 'Timed Exam';
@override String get smart_not_started => 'Not started';
@override String smart_chunks_done({required int done, required int total}) => '$done of $total parts done';
@override String get smart_result_passed => 'Part passed!';
@override String get smart_result_failed => 'Not quite — try again';
@override String smart_result_weak_updated({required int count}) => '$count weak questions updated';
@override String get smart_result_continue => 'Continue';
@override String get smart_no_exams => 'No exams available for Smart Learning yet';
```

- [ ] **Step 5: Add implementations to `strings_sv.g.dart`**

Find the `TranslationsSv` class. Add:

```dart
@override String get smart_learning_title => 'Smart Learning';
@override String get smart_learning_subtitle => 'Träna del för del, bemästra dina svaga punkter';
@override String get smart_chunk_label => 'Smart Learning';
@override String smart_chunk_n({required int n}) => 'Del $n';
@override String get smart_chunk_passed => 'Godkänd';
@override String get smart_chunk_locked => 'Låst';
@override String get smart_chunk_active => 'Starta';
@override String get smart_chunk_retry => 'Försök igen';
@override String get smart_full_exam => 'Fullständigt prov';
@override String get smart_full_exam_locked => 'Slutför alla delar för att låsa upp';
@override String get smart_full_exam_ready => 'Fullständigt prov redo';
@override String smart_train_mistakes({required int count}) => 'Träna misstag ($count)';
@override String get smart_practice_mode => 'Övning';
@override String get smart_timed_mode => 'Tidsbegränsat prov';
@override String get smart_not_started => 'Ej påbörjad';
@override String smart_chunks_done({required int done, required int total}) => '$done av $total delar klara';
@override String get smart_result_passed => 'Del godkänd!';
@override String get smart_result_failed => 'Inte riktigt — försök igen';
@override String smart_result_weak_updated({required int count}) => '$count svaga frågor uppdaterade';
@override String get smart_result_continue => 'Fortsätt';
@override String get smart_no_exams => 'Inga prov tillgängliga för Smart Learning ännu';
```

- [ ] **Step 6: Verify compile**

```bash
flutter analyze lib/core/localization/
```

Expected: `No issues found!`

---

## Task 7: SmartLearningScreen

**Files:**
- Create: `lib/features/smart_learning/smart_learning_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// lib/features/smart_learning/smart_learning_screen.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/features/smart_learning/bcd_chunk_list_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/services/chunk_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/chunk_utils.dart';

/// One entry in the smart learning exam list.
class SmartExamEntry {
  final int testBcdId;
  final String testName;
  final String categoryName;
  final int parentCategoryBcdId;
  final int? parentCategoryBcdIdForTest; // subcategory bcd_id if applicable
  final int questionCount;
  final int passScore;
  final int timeLimit;
  final List<int> chunkSizes;

  const SmartExamEntry({
    required this.testBcdId,
    required this.testName,
    required this.categoryName,
    required this.parentCategoryBcdId,
    this.parentCategoryBcdIdForTest,
    required this.questionCount,
    required this.passScore,
    required this.timeLimit,
    required this.chunkSizes,
  });
}

class SmartLearningScreen extends StatefulWidget {
  const SmartLearningScreen({super.key});

  @override
  State<SmartLearningScreen> createState() => _SmartLearningScreenState();
}

class _SmartLearningScreenState extends State<SmartLearningScreen> {
  final _svc = ChunkProgressService();
  List<SmartExamEntry> _entries = [];
  // testBcdId → chunks passed count
  Map<int, int> _passedCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = _buildEntries();
    final passed = <int, int>{};
    for (final e in entries) {
      final active = await _svc.activeChunkIndex(e.testBcdId, e.chunkSizes.length);
      passed[e.testBcdId] = active;
    }
    if (mounted) {
      setState(() {
        _entries = entries;
        _passedCounts = passed;
        _loading = false;
      });
    }
  }

  List<SmartExamEntry> _buildEntries() {
    final entries = <SmartExamEntry>[];
    final cache = BcdCache.instance;

    for (final cat in cache.categories) {
      final catId = cat['bcd_id'] as int;
      final catName = cat['name']?.toString() ?? '';
      final hasSubs = cat['has_children'] == true;

      if (hasSubs) {
        for (final sub in cache.subcategoriesOf(catId)) {
          final subId = sub['bcd_id'] as int;
          for (final test in cache.testsOf(subId)) {
            final entry = _entryFromTest(test, catName, catId);
            if (entry != null) entries.add(entry);
          }
        }
      } else {
        for (final test in cache.testsOf(catId)) {
          final entry = _entryFromTest(test, catName, catId);
          if (entry != null) entries.add(entry);
        }
      }
    }
    return entries;
  }

  SmartExamEntry? _entryFromTest(
      Map<String, dynamic> test, String catName, int catId) {
    final qc = test['question_count'] as int? ?? 0;
    final sizes = ChunkUtils.computeChunkSizes(qc);
    if (sizes.length <= 1) return null;
    return SmartExamEntry(
      testBcdId: test['bcd_id'] as int,
      testName: test['name']?.toString() ?? '',
      categoryName: catName,
      parentCategoryBcdId: catId,
      questionCount: qc,
      passScore: test['pass_score'] as int? ?? 0,
      timeLimit: test['time_limit'] as int? ?? 0,
      chunkSizes: sizes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(t.smart_learning_title,
            style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text(t.smart_no_exams,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ExamCard(
                      entry: _entries[i],
                      passedCount: _passedCounts[_entries[i].testBcdId] ?? 0,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (_) => BcdChunkListScreen(
                              entry: _entries[i],
                            ),
                          ),
                        );
                        _load(); // refresh progress on return
                      },
                    ),
                  ),
                ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final SmartExamEntry entry;
  final int passedCount;
  final VoidCallback onTap;

  const _ExamCard({
    required this.entry,
    required this.passedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final total = entry.chunkSizes.length;
    final allDone = passedCount >= total;
    final progress = total == 0 ? 0.0 : passedCount / total;

    final statusLabel = allDone
        ? t.smart_full_exam_ready
        : passedCount == 0
            ? t.smart_not_started
            : t.smart_chunks_done(done: passedCount, total: total);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.testName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(entry.categoryName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? Colors.green.shade500 : cs.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(statusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: allDone
                              ? Colors.green.shade600
                              : cs.onSurface.withValues(alpha: 0.6))),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compile**

```bash
flutter analyze lib/features/smart_learning/smart_learning_screen.dart
```

Expected: `No issues found!`

---

## Task 8: BcdChunkListScreen

**Files:**
- Create: `lib/features/smart_learning/bcd_chunk_list_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// lib/features/smart_learning/bcd_chunk_list_screen.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/features/bcd/bcd_test_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/chunk_test_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/services/chunk_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/smart_learning_screen.dart';

class BcdChunkListScreen extends StatefulWidget {
  final SmartExamEntry entry;

  const BcdChunkListScreen({super.key, required this.entry});

  @override
  State<BcdChunkListScreen> createState() => _BcdChunkListScreenState();
}

class _BcdChunkListScreenState extends State<BcdChunkListScreen> {
  final _svc = ChunkProgressService();
  int _activeChunk = 0;
  int _weakCount = 0;
  bool _fullUnlocked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final total = widget.entry.chunkSizes.length;
    final active = await _svc.activeChunkIndex(widget.entry.testBcdId, total);
    final weak = await _svc.weakQuestionCount(widget.entry.testBcdId);
    final unlocked = await _svc.isFullExamUnlocked(widget.entry.testBcdId, total);
    if (mounted) {
      setState(() {
        _activeChunk = active;
        _weakCount = weak;
        _fullUnlocked = unlocked;
        _loading = false;
      });
    }
  }

  Future<void> _startChunk(int chunkIndex) async {
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => ChunkTestScreen(
          entry: widget.entry,
          chunkIndex: chunkIndex,
          isMistakesMode: false,
        ),
      ),
    );
    _load();
  }

  Future<void> _startMistakes() async {
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => ChunkTestScreen(
          entry: widget.entry,
          chunkIndex: -1,
          isMistakesMode: true,
        ),
      ),
    );
    _load();
  }

  void _startFullExam({required bool timed}) {
    final e = widget.entry;
    final qc = e.questionCount;
    final passScorePct = qc > 0 ? (e.passScore / qc * 100) : 75.0;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => BCDTestScreen(
          testId: e.testBcdId,
          testName: e.testName,
          passScore: e.passScore,
          timeLimit: timed ? e.timeLimit : 0,
          parentCategoryName: e.categoryName,
          parentCategoryBcdId: e.parentCategoryBcdId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.smart_learning_title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5))),
            Text(widget.entry.testName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  ...List.generate(widget.entry.chunkSizes.length, (i) {
                    final isPassed = i < _activeChunk;
                    final isActive = i == _activeChunk;
                    final isLocked = i > _activeChunk;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ChunkCard(
                        label: t.smart_chunk_n(n: i + 1),
                        questionCount: widget.entry.chunkSizes[i],
                        isPassed: isPassed,
                        isActive: isActive,
                        isLocked: isLocked,
                        onTap: (!isLocked) ? () => _startChunk(i) : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  if (_weakCount > 0) ...[
                    _TrainMistakesCard(
                      count: _weakCount,
                      onTap: _startMistakes,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _FullExamCard(
                    unlocked: _fullUnlocked,
                    onPractice: _fullUnlocked
                        ? () => _startFullExam(timed: false)
                        : null,
                    onTimed: _fullUnlocked
                        ? () => _startFullExam(timed: true)
                        : null,
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Chunk card ──────────────────────────────────────────────────────────────

class _ChunkCard extends StatelessWidget {
  final String label;
  final int questionCount;
  final bool isPassed;
  final bool isActive;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ChunkCard({
    required this.label,
    required this.questionCount,
    required this.isPassed,
    required this.isActive,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final color = isPassed
        ? Colors.green.shade500
        : isActive
            ? cs.primary
            : cs.onSurface.withValues(alpha: 0.25);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? cs.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed
                      ? Icons.check_rounded
                      : isLocked
                          ? Icons.lock_outline_rounded
                          : Icons.play_arrow_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('$questionCount questions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Text(
                isPassed
                    ? t.smart_chunk_passed
                    : isActive
                        ? t.smart_chunk_active
                        : t.smart_chunk_locked,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Train Mistakes card ──────────────────────────────────────────────────────

class _TrainMistakesCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _TrainMistakesCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.smart_train_mistakes(count: count),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.error, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.error.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Full Exam card ───────────────────────────────────────────────────────────

class _FullExamCard extends StatelessWidget {
  final bool unlocked;
  final VoidCallback? onPractice;
  final VoidCallback? onTimed;

  const _FullExamCard({
    required this.unlocked,
    this.onPractice,
    this.onTimed,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: unlocked ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? Colors.green.shade400.withValues(alpha: 0.4)
                : cs.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  unlocked
                      ? Icons.emoji_events_rounded
                      : Icons.lock_outline_rounded,
                  color: unlocked ? Colors.amber.shade600 : cs.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(t.smart_full_exam,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              unlocked ? t.smart_full_exam_ready : t.smart_full_exam_locked,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55)),
            ),
            if (unlocked) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPractice,
                      child: Text(t.smart_practice_mode),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onTimed,
                      child: Text(t.smart_timed_mode),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compile**

```bash
flutter analyze lib/features/smart_learning/bcd_chunk_list_screen.dart
```

Expected: `No issues found!`

---

## Task 9: ChunkTestScreen

**Files:**
- Create: `lib/features/smart_learning/chunk_test_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// lib/features/smart_learning/chunk_test_screen.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/widgets/option_tile.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/bcd/providers/bcd_provider.dart';
import 'package:taxi_exam_app/features/smart_learning/services/chunk_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/services/chunk_session_builder.dart';
import 'package:taxi_exam_app/features/smart_learning/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/chunk_utils.dart';

class ChunkTestScreen extends StatefulWidget {
  final SmartExamEntry entry;
  final int chunkIndex; // -1 for Train Mistakes
  final bool isMistakesMode;

  const ChunkTestScreen({
    super.key,
    required this.entry,
    required this.chunkIndex,
    required this.isMistakesMode,
  });

  @override
  State<ChunkTestScreen> createState() => _ChunkTestScreenState();
}

class _ChunkTestScreenState extends State<ChunkTestScreen> {
  final _provider = BcdProvider();
  final _svc = ChunkProgressService();

  ChunkQueueManager? _queue;
  String? _selectedOption;
  bool _submitted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onProviderChange);
    _provider.loadTestQuestions(widget.entry.testBcdId);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    if (_provider.testQuestionsError != null) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_test_questions,
            type: SnackBarType.error);
        Navigator.pop(context);
      }
      return;
    }
    if (!_provider.testQuestionsLoading && _provider.testQuestions.isNotEmpty) {
      _buildSession(_provider.testQuestions);
    }
  }

  Future<void> _buildSession(List<Question> all) async {
    List<Question> sessionQuestions;

    if (widget.isMistakesMode) {
      final weakIds = await _svc.allWeakQuestionIds(widget.entry.testBcdId);
      sessionQuestions = weakIds
          .map((id) => all.firstWhere((q) => q.questionId == id,
              orElse: () => all.first))
          .toList();
    } else {
      final sizes = ChunkUtils.computeChunkSizes(all.length);
      final weakIds = await _svc.weakQuestionIdsFor(
          widget.entry.testBcdId, sizes[widget.chunkIndex]);
      sessionQuestions = ChunkSessionBuilder.build(
        allQuestions: all,
        chunkSizes: sizes,
        chunkIndex: widget.chunkIndex,
        weakQuestionIds: weakIds,
      );
    }

    if (mounted) {
      setState(() {
        _queue = ChunkQueueManager(sessionQuestions);
        _loading = false;
      });
    }
  }

  void _selectOption(String label) {
    if (_submitted) return;
    setState(() => _selectedOption = label);
  }

  void _submit() {
    if (_selectedOption == null || _queue == null) return;
    final isCorrect =
        _selectedOption == _queue!.current.correctAnswer;
    setState(() => _submitted = true);
    _queue!.answer(isCorrect);
  }

  void _next() {
    if (_queue == null) return;
    if (_queue!.isDone) {
      _finishSession();
      return;
    }
    setState(() {
      _selectedOption = null;
      _submitted = false;
    });
  }

  Future<void> _finishSession() async {
    final queue = _queue!;
    final score = queue.score;
    final passed = !widget.isMistakesMode && score >= 0.70;

    await _svc.recordSessionResults(
        widget.entry.testBcdId, queue.firstAttempts);

    if (!widget.isMistakesMode) {
      await _svc.recordChunkResult(
          widget.entry.testBcdId, widget.chunkIndex, passed);
    }

    if (!mounted) return;
    _showResultSheet(score: score, passed: passed);
  }

  void _showResultSheet({required double score, required bool passed}) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final color = passed ? Colors.green.shade500 : cs.error;
    final weakUpdated =
        _queue!.firstAttempts.values.where((v) => !v).length;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.check_rounded : Icons.close_rounded,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isMistakesMode
                    ? '${(score * 100).toInt()}%'
                    : (passed ? t.smart_result_passed : t.smart_result_failed),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${(score * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              if (weakUpdated > 0) ...[
                const SizedBox(height: 8),
                Text(
                  t.smart_result_weak_updated(count: weakUpdated),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55)),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context); // close sheet
                    Navigator.pop(context); // return to chunk list
                  },
                  child: Text(t.smart_result_continue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_loading || _queue == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: AppBackButton(onPressed: () => Navigator.pop(context)),
          title: Text(t.smart_chunk_label),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _queue!.current;
    final options = question.options;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.smart_chunk_label,
            style: Theme.of(context).textTheme.titleMedium),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _QuestionView(
          key: ValueKey(question.questionId + _submitted.toString()),
          question: question,
          selectedOption: _selectedOption,
          submitted: _submitted,
          onSelect: _selectOption,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _submitted
              ? SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(_queue!.isDone
                        ? t.smart_result_continue
                        : t.smart_chunk_active),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _selectedOption != null ? _submit : null,
                    child: const Text('Submit'),
                  ),
                ),
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final Question question;
  final String? selectedOption;
  final bool submitted;
  final ValueChanged<String> onSelect;

  const _QuestionView({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.submitted,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              question.text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 14),
          ...question.options.map((opt) {
            final isSelected = selectedOption == opt.optionLabel;
            final isCorrect = opt.optionLabel == question.correctAnswer;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OptionTile(
                option: opt,
                isSelected: isSelected,
                isCorrect: submitted ? isCorrect : null,
                isInstantMarking: submitted,
                onTap: () => onSelect(opt.optionLabel),
              ),
            );
          }),
          if (submitted && question.answerExplanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                question.answerExplanation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compile**

```bash
flutter analyze lib/features/smart_learning/chunk_test_screen.dart
```

Expected: `No issues found!`

---

## Task 10: Home Screen Entry Point

**Files:**
- Modify: `lib/features/home/home_screen.dart`

- [ ] **Step 1: Add import**

At the top of `home_screen.dart`, add:

```dart
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/smart_learning/smart_learning_screen.dart';
```

- [ ] **Step 2: Add `_buildSmartLearningCard` method**

Add this private method to the `_HomeScreenState` class (after `_buildEmptyState`):

```dart
Widget _buildSmartLearningCard() {
  final t = Translations.of(context);
  final cs = Theme.of(context).colorScheme;

  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      AppPageRoute(builder: (_) => const SmartLearningScreen()),
    ),
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology_rounded, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.smart_learning_title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: cs.primary)),
                const SizedBox(height: 2),
                Text(t.smart_learning_subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: cs.primary.withValues(alpha: 0.6)),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 3: Insert card into the sliver list**

In `home_screen.dart`, find the `if (hasData) ...[` block. Insert the Smart Learning card right before the hero card `SliverToBoxAdapter`:

```dart
// Smart Learning entry point
SliverToBoxAdapter(child: _buildSmartLearningCard()),
const SliverToBoxAdapter(child: SizedBox(height: 4)),
// Hero card
SliverToBoxAdapter(child: _buildHeroCard(avgScore, passed, failed)),
```

Also insert it in the `else if (_pausedAttempts.isNotEmpty)` branch (before `_buildInProgressSection`):

```dart
} else if (_pausedAttempts.isNotEmpty) ...[
  SliverToBoxAdapter(child: _buildSmartLearningCard()),
  const SliverToBoxAdapter(child: SizedBox(height: 4)),
  SliverToBoxAdapter(child: _buildInProgressSection(t)),
```

And in the `else` empty-state branch:

```dart
] else ...[
  SliverToBoxAdapter(child: _buildSmartLearningCard()),
  const SliverToBoxAdapter(child: SizedBox(height: 4)),
  SliverFillRemaining(child: _buildEmptyState(t)),
],
```

- [ ] **Step 4: Verify full app compiles**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

---

## Task 11: Final Verification

- [ ] **Step 1: Run all new tests**

```bash
flutter test test/features/smart_learning/
```

Expected: All tests pass.

- [ ] **Step 2: Check for any remaining analyzer issues**

```bash
flutter analyze lib/features/smart_learning/ lib/core/storage/app_storage.dart lib/main.dart lib/features/home/home_screen.dart lib/core/localization/
```

Expected: `No issues found!`

- [ ] **Step 3: Verify Hive typeId uniqueness**

Confirm no typeId conflicts exist:
- 0: TestAttempt
- 1: Question
- 2: Option
- 3: LocalNotification
- 4: SubscribedExam
- 5: ExamNode
- 6: ChunkProgress ← new
- 7: WeakQuestion ← new

---

## Self-Review Notes

- `OptionTile` constructor — verify its actual parameter names before Task 9 (it uses `option`, `isSelected`, `isCorrect`, `isInstantMarking`, `onTap`; adjust if different)
- `AppBackButton` — used throughout; already exists in `lib/core/widgets/app_back_button.dart`
- `AppPageRoute` — used for navigation; exists in `lib/core/utils/app_page_route.dart`
- `SnackBarType.error` — used in ChunkTestScreen; verify the import from `lib/core/widgets/snackbar.dart`
- The `BcdProvider` is a singleton (`factory BcdProvider() => _instance`) — safe to instantiate multiple times
- All colors use `Theme.of(context).colorScheme.*` — no hardcoded hex values
- All strings use `Translations.of(context).*` — no hardcoded English
