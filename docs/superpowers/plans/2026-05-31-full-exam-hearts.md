# Full Exam Mock Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the separate Smart Learning full-exam screen with the main timed `Testscreen`, showing hearts only when the user has not completed the previous parts.

**Architecture:** Add an explicit mock-exam mode to `Testscreen` so the AppBar can render timer-only or timer-plus-hearts without the overflow menu. Pass that configuration through `BCDTestScreen`, then update `SmartExamScreen` to offer a single timed full-exam CTA and choose hearts based on Smart Learning progress.

**Tech Stack:** Flutter, Dart, widget tests, existing `Testscreen`, `BCDTestScreen`, `SmartProgressService`.

---

### Task 1: Cover mock-exam header and hearts behavior with tests

**Files:**
- Create: `test/features/tests/test_screen_mock_exam_test.dart`

- [ ] Add a widget test that pumps `Testscreen` in normal mode and verifies the overflow menu is still present.
- [ ] Add a widget test that pumps `Testscreen` in mock-exam mode and verifies the overflow menu is hidden while the timer chip is visible.
- [ ] Add a widget test that pumps `Testscreen` in mock-exam hearts mode, answers three wrong questions, and verifies the game-over callback fires.
- [ ] Run the focused test file and confirm it fails for the new mock-exam expectations before production edits.

### Task 2: Implement mock-exam mode inside `Testscreen`

**Files:**
- Modify: `lib/features/tests/test_screen.dart`

- [ ] Add explicit mock-exam configuration to `Testscreen`.
- [ ] Hide translation/feedback/timer-toggle/instant-marking controls when mock-exam mode is enabled.
- [ ] Keep timer visible in mock-exam mode and show hearts only when a max-wrong limit is configured.
- [ ] Track wrong answers in mock-exam hearts mode even though instant marking is disabled.
- [ ] Trigger the game-over callback on the third wrong answer.
- [ ] Keep existing non-mock test behavior unchanged.

### Task 3: Pass mock-exam configuration through `BCDTestScreen`

**Files:**
- Modify: `lib/features/bcd/bcd_test_screen.dart`

- [ ] Add passthrough parameters for mock-exam mode, hearts limit, and game-over callback.
- [ ] Forward those values into the `Testscreen` instance created after question loading.

### Task 4: Switch Smart Learning to a single timed mock-exam entry

**Files:**
- Modify: `lib/features/smart_learning/screens/smart_exam_screen.dart`
- Delete or stop using: `lib/features/smart_learning/screens/smart_full_exam_screen.dart`

- [ ] Replace the dual Practice/Timed full-exam CTA with one timed CTA.
- [ ] Route Smart Learning full exams through the existing BCD -> `Testscreen` path.
- [ ] Enable hearts only when the user has not completed all prerequisite chunks.
- [ ] Reuse the localized game-over sheet after hearts are depleted.

### Task 5: Verify focused behavior

**Files:**
- Verify only

- [ ] Run the new focused widget tests.
- [ ] Run `dart analyze` on the touched files.
- [ ] Report actual verification output without committing anything.
