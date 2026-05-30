# Smart Learning — Design Spec
**Date:** 2026-05-30
**Status:** Approved

---

## Overview

Add an optional "Smart Learning" mode to the TaxiQuiz app. The existing BCD exam flow is completely untouched. Smart Learning is a separate entry point that trains users chunk by chunk, tracks weak questions, and unlocks the full exam only after all chunks are passed.

---

## Scope

### In scope
- Auto-chunking algorithm (client-side, no backend changes)
- Weak question pool with spaced-repetition-style carry-forward
- Within-session re-ask for wrong answers
- `SmartLearningScreen` — exam list with progress
- `BcdChunkListScreen` — chunk map, Train Mistakes, Full Exam unlock
- `ChunkTestScreen` — chunk session runner
- New Hive models: `ChunkProgress`, `WeakQuestion`
- New service: `ChunkProgressService`
- New utility: `ChunkUtils`
- New service: `ChunkSessionBuilder` + `ChunkQueueManager`
- Translation keys for all new strings (EN + SV)
- Full dark/light mode support

### Out of scope
- Backend changes (no new models, endpoints, or pipeline modifications)
- Changes to `Testscreen`, `BCDTestScreen`, `BcdCategoryHubScreen` (all untouched)
- Self endpoint modifications

---

## Architecture

### Folder structure

```
lib/features/smart_learning/
  smart_learning_screen.dart       # exam list + progress
  bcd_chunk_list_screen.dart       # chunk map for one exam
  chunk_test_screen.dart           # chunk session runner
  services/
    chunk_progress_service.dart
    chunk_session_builder.dart
  utils/
    chunk_utils.dart
  models/
    chunk_progress.dart + .g.dart  # Hive typeId: 3
    weak_question.dart + .g.dart   # Hive typeId: 4
```

**Zero changes to existing screens.** All new code is fully self-contained under `lib/features/smart_learning/`.
`ChunkTestScreen` is a standalone screen — it does not wrap `Testscreen` because `Testscreen` uses a fixed `PageView` that cannot support dynamic question re-insertion.

---

## Section 1 — Data Layer

### Hive model: `ChunkProgress` (typeId: 3)

```dart
@HiveType(typeId: 3)
class ChunkProgress {
  @HiveField(0) final int      testBcdId;
  @HiveField(1) final int      chunkIndex;    // 0-based
  @HiveField(2) final bool     isPassed;      // score >= 70%
  @HiveField(3) final DateTime completedAt;
}
```

Box name: `'chunkProgress'`
Box key: `'$testBcdId-$chunkIndex'`

### Hive model: `WeakQuestion` (typeId: 4)

```dart
@HiveType(typeId: 4)
class WeakQuestion {
  @HiveField(0) final int      testBcdId;
  @HiveField(1) final String   questionId;    // BCD question ID
  @HiveField(2)       int      wrongCount;
  @HiveField(3)       int      correctStreak; // resets on wrong; graduates at >= 3
  @HiveField(4)       DateTime lastSeen;
}
```

Box name: `'weakQuestions'`
Box key: `'$testBcdId-$questionId'`

### `ChunkProgressService`
`lib/features/smart_learning/services/chunk_progress_service.dart`

```dart
// Returns 0-based index of the first unpassed chunk
int activeChunkIndex(int testBcdId, int totalChunks)

// Persist pass/fail for a chunk
Future<void> recordChunkResult(int testBcdId, int chunkIndex, bool passed)

// Update weak pool from session results.
// questionResults: Map<questionId, wasCorrect (first attempt)>
// Graduation: correctStreak >= 3 → delete entry
Future<void> recordSessionResults(int testBcdId, Map<String, bool> questionResults)

// Returns question IDs to inject into next chunk (capped at 30% of chunkSize)
// Sorted by wrongCount desc (most-wrong first)
List<String> weakQuestionIdsFor(int testBcdId, int chunkSize)

// True when every chunk index 0..totalChunks-1 has isPassed = true
bool isFullExamUnlocked(int testBcdId, int totalChunks)

// All weak question IDs for Train Mistakes mode
List<String> allWeakQuestionIds(int testBcdId)
```

---

## Section 2 — Chunk Algorithm & Session Builder

### `ChunkUtils`
`lib/features/smart_learning/utils/chunk_utils.dart`

```dart
/// Returns the size of each chunk. Single-element list = no chunking.
/// Rules:
///   total <= 10          → [total]  (no split)
///   total <= 25          → target chunk size = 10
///   total >  25          → target chunk size = 15
/// Remainder distributed across leading chunks (+1 each).
static List<int> computeChunkSizes(int total)

/// Start index in the full question list for a given chunk index.
static int chunkOffset(List<int> sizes, int chunkIndex)
```

Examples:
| Total | Sizes |
|-------|-------|
| 10    | [10] — no split |
| 15    | [8, 7] |
| 20    | [10, 10] |
| 40    | [14, 13, 13] |
| 70    | [14, 14, 14, 14, 14] |

### `ChunkSessionBuilder`
`lib/features/smart_learning/services/chunk_session_builder.dart`

Builds the question list for one chunk session:

```dart
static List<Question> build({
  required List<Question> allQuestions,   // full parent test list (consistent order)
  required List<int>      chunkSizes,
  required int            chunkIndex,
  required List<String>   weakQuestionIds, // from ChunkProgressService
})
```

Algorithm:
1. Slice `allQuestions` using `chunkOffset` + `chunkSizes[chunkIndex]` — same base questions every retry
2. Inject weak questions: exclude any already in base, take up to `floor(chunkSize * 0.3)` from weakQuestionIds
3. Shuffle the combined list (base + weak) — hidden session length

### `ChunkQueueManager`

Lives as a private class inside `ChunkTestScreen` state. Manages the mutable re-ask queue.

```dart
class ChunkQueueManager {
  // answer(correct): records first attempt, re-inserts at random if wrong
  // each question re-asked at most once per session
  void answer(bool correct)

  Question get current
  bool     get isDone

  // Score = correctly answered on first attempt / total unique questions
  double get score

  // Map<questionId, wasCorrect> for first attempts — passed to recordSessionResults
  Map<String, bool> get firstAttempts
}
```

Re-insert rule: if wrong and not yet re-asked → insert at `cursor + 1 + Random().nextInt(remaining)`.
Score is **first-attempt only** — re-asks do not inflate or deflate the score.

---

## Section 3 — UI & Navigation

### Entry point

One new card on the **home dashboard** (`home_screen.dart`):
- Label: `t.smart_learning_title`
- Subtitle: `t.smart_learning_subtitle`
- Shown always (not conditional on subscription — Smart Learning works with whatever exams the user has access to)
- Navigates to `SmartLearningScreen`

### `SmartLearningScreen`

Lists all BCD exams where `computeChunkSizes(questionCount).length > 1`.
`questionCount` comes from `BcdCache.testsOf(categoryBcdId)` — each test map already contains `question_count` from the `/self` response.
For each exam shows:
- Exam name
- Progress bar: chunks passed / total chunks
- State label: not started / X of N chunks / full exam ready

Tapping an exam → `BcdChunkListScreen`.

### `BcdChunkListScreen`

Shows the full chunk map for one exam:

| Card | State | Action |
|------|-------|--------|
| Chunk N | locked | not tappable |
| Chunk N | active (first unpassed) | tappable → `ChunkTestScreen` |
| Chunk N | passed | tappable → retry allowed |
| Train Mistakes | visible if weak pool > 0 | → `ChunkTestScreen` in mistakes mode |
| Full Exam | locked until all chunks passed | shows two buttons: Practice / Full Exam |

Full Exam — Practice: `BCDTestScreen` with `instantMarking: true`, `isTimed: false`
Full Exam — Timed: `BCDTestScreen` with `instantMarking: false`, `isTimed: true`
Both use the existing `BCDTestScreen` unchanged.

### `ChunkTestScreen`

Standalone stateful screen — does **not** wrap `Testscreen`. Uses shared widgets directly (`QuestionPageItem`, `OptionTile`, `NavigationControls`).

State holds a `ChunkQueueManager` instance. Questions are rendered one at a time (no `PageView` — a simple `AnimatedSwitcher` over the current question). No question count shown anywhere in the UI.

Lifecycle:
1. On init: load all parent test questions via `BcdProvider.loadTestQuestions(parentTestId)` (cached)
2. Build session: `ChunkSessionBuilder.build(...)` → pass to `ChunkQueueManager`
3. Render current question; user picks option → `queue.answer(correct)`
4. When `queue.isDone`: call `ChunkProgressService.recordSessionResults(queue.firstAttempts)`
5. Call `ChunkProgressService.recordChunkResult(chunkIndex, score >= 0.7)`
6. Show result bottom sheet: passed/failed badge, score, weak pool delta
7. Pop back to `BcdChunkListScreen`

Train Mistakes mode: same screen, `chunkIndex: -1`, questions = weak pool only, no pass threshold applied.

### No changes to existing screens

`Testscreen`, `BCDTestScreen`, `BcdCategoryHubScreen` — all untouched. The only modification to existing code is one new card added to `home_screen.dart`.

### Navigation tree

```
HomeScreen
  └── Smart Learning card
        └── SmartLearningScreen
              └── BcdChunkListScreen (per exam)
                    ├── ChunkTestScreen (chunk N)
                    ├── ChunkTestScreen (Train Mistakes)
                    └── BCDTestScreen   (Full Exam — untouched)
```

---

## Section 4 — Design Standards

All new screens **must** follow these rules. No exceptions.

| Concern | Rule |
|---------|------|
| Backgrounds | `Theme.of(context).scaffoldBackgroundColor` |
| Cards/surfaces | `Theme.of(context).colorScheme.surface` |
| Primary color | `Theme.of(context).colorScheme.primary` |
| Text on surface | `Theme.of(context).colorScheme.onSurface` |
| Error/fail | `Theme.of(context).colorScheme.error` |
| Text styles | `Theme.of(context).textTheme.titleLarge` etc. — never hardcoded fontSize |
| Strings | `final t = Translations.of(context);` — all user-facing text via slang keys |
| Dark mode | No hardcoded colors — `ThemeProvider` handles `themeMode` automatically |

### New translation keys

Add to all 4 files: `strings.i18n.json`, `strings_sv.i18n.json`, `strings_en.g.dart`, `strings_sv.g.dart`

```
smart_learning_title
smart_learning_subtitle
smart_chunk_label
smart_chunk_passed
smart_chunk_locked
smart_chunk_active
smart_full_exam
smart_full_exam_locked
smart_full_exam_ready
smart_train_mistakes          (includes {count} placeholder)
smart_practice_mode
smart_timed_mode
smart_not_started
smart_chunks_done             ({done} of {total})
smart_result_passed
smart_result_failed
smart_result_weak_updated     ({count} weak questions updated)
test_smart_chunk_label        (replaces Q X/N header during chunks)
```

---

## Progression Rules Summary

```
Chunk session score >= 70%  → isPassed = true, next chunk unlocks
Chunk session score <  70%  → isPassed = false, retry same chunk
Wrong question              → added to weak pool (wrongCount++, streak = 0)
Correct question            → correctStreak++; if streak >= 3 → graduated (deleted)
Next chunk session          → injects up to 30% weak questions alongside base slice
Full exam unlocks           → when ALL chunks isPassed = true
Train Mistakes              → available any time weak pool is non-empty
```

---

## Open Questions / Decisions Made

| Question | Decision |
|----------|----------|
| Backend changes? | None — fully client-side |
| Self endpoint | Keep as-is |
| Chunk sizes | Auto-algorithm: target 10 (≤25 questions) or 15 (>25) |
| Pass threshold | 70% per chunk |
| Weak graduation | 3 consecutive correct answers |
| Re-ask limit | Once per question per session |
| Weak injection cap | 30% of chunk size |
| Full exam entry | User picks: Practice or Timed (both use existing BCDTestScreen) |
| Question count during chunks | Hidden |
| Timer during chunks | Off |
