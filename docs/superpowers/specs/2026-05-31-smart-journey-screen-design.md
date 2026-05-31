# Smart Journey Screen — Design Spec

**Date:** 2026-05-31
**Status:** Approved

---

## Overview

Replace the per-exam `SmartExamScreen` with a single scrollable **SmartJourneyScreen** that shows every chunk across all exams in a sub-category as a Duolingo-style snake path. The user sees their complete learning journey — from the first chunk at the bottom to the Full Category Exam goal at the top — in one screen.

---

## Navigation Change

**Before:**
```
SmartLearningScreen (category list)
  → SmartLearningScreen (filtered exam rows)    ← removed
    → SmartExamScreen (per-exam chunks)          ← removed
```

**After:**
```
SmartLearningScreen (category list)
  → SmartJourneyScreen (all exams + path)
```

`SmartExamScreen` is no longer used in this flow. `SmartLearningScreen` passes all `SmartExamEntry` objects for the tapped category directly to `SmartJourneyScreen`.

---

## Screen Layout

```
┌─────────────────────────────────┐
│  ← Traffic Signs                │  AppBar (category name)
├─────────────────────────────────┤
│  ⚠ Train Mistakes (7 q's)  ›    │  Sticky card — only when weakCount > 0
├─────────────────────────────────┤  (SliverPersistentHeader, pinned)
│                                 │
│          🏆 Slutprovet          │  Hexagonal goal node (top of path)
│       Full Category Exam        │  Locked until all chunks done + mastery ≥ 70%
│                                 │
│  ─────── Delprov Körning ──────  │  Section pill — last exam name
│                                 │
│   🔒        🔒        🔒        │  Chunk nodes, snake pattern
│       🔒         🔒             │
│                                 │
│  ─────── Delprov Regler ──────   │  Section pill — first exam name
│                                 │
│    ✓         ▶ Du är här        │  Completed + Active nodes
│                                 │
└─────────────────────────────────┘
         scroll ↑ = progress
```

**Path direction:** bottom = start, top = goal.  
**Auto-scroll:** On open, the screen scrolls to bring the active node into view.

---

## Node Types

### Chunk nodes (circles, ~64 px diameter)

| State | Visual |
|---|---|
| Completed | Filled green, checkmark icon |
| Active | Filled green/primary, play icon, "Du är här" tooltip above |
| Locked | White circle, lock icon, 40% opacity |

### Section pills
- Rounded pill shape, exam name as label
- Sit between exam groups in the scroll flow
- Do not interrupt the path curve — drawn as an overlay on the path

### Goal node (hexagon)

| State | Visual |
|---|---|
| Locked | Dimmed hexagon, lock icon, subtitle "Complete all parts to unlock" |
| Unlocked | Full-color hexagon, trophy icon, subtitle "Ready!" |

Tapping the unlocked goal opens a bottom sheet with **Practice** and **Timed Exam** buttons.

---

## Locking Rules

- **Within an exam:** chunk N+1 is locked until chunk N is passed (existing behaviour).
- **Across exams:** Exam N is fully locked until every chunk of Exam N-1 is passed.
- **Goal node:** locked until all chunks across all exams are passed AND combined mastery ≥ 70%.
- Combined mastery = `totalMastered / totalQuestions` across all exams in the category.

---

## Snake Path Algorithm

1. Build a flat ordered list of **display items**:
   - Reversed exam order (last exam at top of list, first exam at bottom)
   - For each exam: its chunk nodes in order, preceded by a `SectionLabel` item
   - Goal node prepended at the very top
2. Assign each node a (x, y) position using a zigzag layout:
   - Rows of 2–3 nodes alternating left→right / right→left
   - Section label pills span full width and reset the zigzag direction
3. `CustomPainter` (`JourneyPathPainter`) draws a smooth bezier curve through all node centres in order.
4. Nodes and labels are rendered as widgets positioned in a `Stack` over the painted path.

---

## Train Mistakes Card (Sticky)

- Shown only when `weakQuestionCount > 0` across the category.
- Implemented as a `SliverPersistentHeader` with `pinned: true` — stays visible at the top while scrolling.
- Taps into `SmartCategoryMistakesScreen` (no change to that screen).
- When `weakCount == 0`, the sliver collapses to zero height.

---

## Full Category Exam Session

When the goal node is tapped and unlocked, a bottom sheet appears with Practice / Timed buttons. Tapping either:

1. Fetches all questions from every `testBcdId` in the category (same multi-fetch logic as `SmartCategoryMistakesScreen` but without the weak-question filter).
2. Shuffles the combined question list.
3. Pushes `SmartTestScreen` with `passScorePercent: primaryEntry.passScore` and a combined `onComplete` that records results per-exam via `SmartProgressService.recordSessionResults`.
4. Posts to `SmartResultScreen` on completion.

For the timed variant, the time limit is the sum of all exams' `timeLimit` values (or the max, whichever is more appropriate — to be decided during implementation).

---

## New Files

| File | Purpose |
|---|---|
| `lib/features/smart_learning/screens/smart_journey_screen.dart` | Main screen — loads progress, builds node list, hosts scroll view |
| `lib/features/smart_learning/widgets/journey_path_painter.dart` | `CustomPainter` — draws bezier snake path between node centres |
| `lib/features/smart_learning/widgets/journey_node_widget.dart` | Circular chunk node + hexagonal goal node widgets |

---

## Modified Files

| File | Change |
|---|---|
| `lib/features/smart_learning/screens/smart_learning_screen.dart` | Category row `onTap` pushes `SmartJourneyScreen(entries: catEntries)` instead of filtered `SmartLearningScreen` |

---

## Out of Scope

- Animations on the path (glow, pulse on active node) — can be added later.
- Per-node mastery indicators — not needed for MVP.
- Deep-link scrolling to a specific node from a notification.
- Any change to `SmartExamScreen` — it stays as-is, just not used by this flow.

---

## Localization

New keys needed (add to both `strings.i18n.json` and `strings_sv.i18n.json`):

| Key | EN | SV |
|---|---|---|
| `smart_journey_goal_label` | `"Full Category Exam"` | `"Fullständigt kategoriprov"` |
| `smart_journey_goal_locked` | `"Complete all parts to unlock"` | `"Slutför alla delar för att låsa upp"` |
| `smart_journey_goal_ready` | `"Ready!"` | `"Redo!"` |
| `smart_journey_you_are_here` | `"You're here"` | `"Du är här"` |
| `smart_journey_full_review` | `"Full Mistakes Review"` | `"Fullständig felgranskning"` |
