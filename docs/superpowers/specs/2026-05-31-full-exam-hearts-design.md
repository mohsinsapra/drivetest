# Full Exam Mock Mode With Conditional Hearts — Design Spec
Date: 2026-05-31

## Overview
Replace the separate Smart Full Exam screen with the existing main `Testscreen` and make the Smart Learning full exam behave like a real timed mock exam. The user gets a single timed full-exam entry. If they have not completed the previous Smart Learning parts, the mock exam allows entry but adds a 3-hearts limit. If they have completed the previous parts, the same timed mock exam runs without hearts. In both cases, there is no instant marking during the attempt.

## Goals
- Use the existing main `Testscreen` instead of `SmartFullExamScreen`.
- Keep only one full-exam CTA in Smart Learning: timed mock exam.
- Make mock exam UI feel like a real exam:
  - show timer only, or timer plus hearts
  - do not show the three-dots menu
  - do not allow translation during the attempt
  - do not allow feedback/reporting during the attempt
  - do not show instant marking while answering
- End the exam early with a game-over sheet only when hearts mode is active and the user loses all 3 lives.

## Scope
Primary files:
- `lib/features/tests/test_screen.dart`
- `lib/features/smart_learning/screens/smart_exam_screen.dart`

Likely cleanup:
- `lib/features/smart_learning/screens/smart_full_exam_screen.dart`

## Current Problem
- `SmartExamScreen` currently launches a separate `SmartFullExamScreen`.
- The real test infrastructure and top-bar behavior already live in `Testscreen`.
- The current `Testscreen` AppBar always assumes the overflow menu is available for translation, feedback, timer toggle, and instant-marking toggle.
- The previous draft design still assumed separate practice/timed full-exam modes, which no longer matches the desired UX.

## Proposed Design

### 1. Smart Learning launches `Testscreen` directly
`SmartExamScreen` should stop routing full exams through `SmartFullExamScreen`. Instead, it should launch the existing test flow directly using the same underlying BCD test path that ends in `Testscreen`.

The Smart Learning full-exam card becomes a single-action timed mock-exam entry:
- no separate Practice button
- no untimed full-exam mode in Smart Learning

### 2. Add an explicit mock-exam mode to `Testscreen`
`Testscreen` should get a dedicated configuration for real-exam behavior instead of inferring it from loosely related flags.

Expected behavior for mock-exam mode:
- timer is always shown
- progress title remains compatible with the existing screen structure
- no three-dots menu
- no translation controls
- no feedback entry
- no timer toggle
- no instant-marking toggle
- question answers are evaluated only at finish, timer expiry, or hearts depletion

This mode should be isolated so current non-mock test sessions behave exactly as before.

### 3. Hearts are conditional, not a separate exam type
Mock-exam mode can optionally enable hearts:
- prerequisites not completed: `maxWrongAnswers = 3`
- prerequisites completed: `maxWrongAnswers = null`

Wrong answers should still be tracked during the attempt even though instant marking is hidden from the user. When hearts mode is active:
- each wrong answer decrements one life
- correct answers do not affect hearts
- losing the final heart exits the exam and triggers the existing Smart Learning game-over sheet

When hearts mode is not active:
- the user continues through the full timed mock exam normally
- final evaluation happens only at completion/time expiry

### 4. Top bar behavior
In Smart Learning mock-exam mode, the AppBar actions become:
- timer only, when hearts are disabled
- timer plus hearts, when hearts are enabled

The three-dots menu is never shown in this mode.

Hearts should be displayed as a compact visual indicator suitable for the existing AppBar. The current spec does not require a text label in the header; the primary purpose is fast visual status.

### 5. Game-over behavior
When hearts reach zero:
- close the active exam screen
- return control to `SmartExamScreen`
- show the existing localized game-over bottom sheet:
  - title: `smart_hearts_game_over_title`
  - body: `smart_hearts_game_over_body`
  - primary button: `smart_hearts_keep_practising`

No partial-attempt recovery or heart persistence is needed.

## Data Flow
1. User opens Smart Learning exam screen.
2. User taps the single timed full-exam CTA.
3. `SmartExamScreen` determines whether the user has completed prerequisite parts.
4. Smart Learning launches the existing test flow in mock-exam mode.
5. `Testscreen` renders:
   - timer only, or
   - timer plus hearts
6. User answers questions without instant marking.
7. If hearts mode is active, wrong answers decrement lives internally.
8. On zero hearts:
   - test closes
   - Smart Learning shows game-over sheet
9. Otherwise the attempt ends through normal finish or timer expiry and uses the existing result flow.

## Error Handling And Guardrails
- Mock-exam mode must not affect existing non-Smart-Learning test flows.
- If the game-over callback is absent while hearts are enabled, the test should fail safely by not crashing; early-exit behavior should be guarded.
- Timer handling must remain single-source-of-truth; mock-exam mode should not introduce a second timer implementation.
- Removing the overflow menu in mock-exam mode must not break the translation tutorial or review flows outside mock exams.

## Out Of Scope
- Reworking the general test result UI
- Persisting hearts between sessions
- Adding explanations during the exam
- Supporting an untimed Smart Learning full exam
- Keeping or evolving `SmartFullExamScreen` as a parallel implementation

## Open Implementation Notes
- The existing `SmartFullExamScreen` should likely be removed after the main-screen path is wired in, unless another caller still depends on it.
- If `BCDTestScreen` is the cleanest route into `Testscreen`, it may need a small passthrough for mock-exam configuration.
- The mock-exam configuration should be named explicitly enough to avoid future confusion with `hideProgress` or other unrelated flags.
