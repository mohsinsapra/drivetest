# Smart Journey Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the per-exam SmartExamScreen with a Duolingo-style snake-path `SmartJourneyScreen` that shows every chunk across all exams in a category on one scrollable screen, with a hexagonal Full Category Exam goal at the top.

**Architecture:** A flat ordered list of `JourneyItem` sealed types (GoalNode, SectionLabel, StageNode) is built from `List<SmartExamEntry>` + progress data. A `CustomPainter` draws a bezier snake path through pre-computed node positions; node and label widgets are `Positioned` in a `Stack` on top. A pinned `SliverPersistentHeader` holds the Train Mistakes card when weak questions exist.

**Tech Stack:** Flutter, Hive (existing), `SmartProgressService` (existing), `BcdProvider` (existing), slang localization, `Theme.of(context)` for all colors, `dart:math` for hex painting.

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `lib/features/smart_learning/utils/journey_utils.dart` | Create | JourneyItem models + `buildJourneyItems` + position helpers |
| `lib/features/smart_learning/widgets/journey_path_painter.dart` | Create | `CustomPainter` for the bezier snake path |
| `lib/features/smart_learning/widgets/journey_node_widget.dart` | Create | Circular chunk node, hexagonal goal node, section pill, "Du är här" chip |
| `lib/features/smart_learning/screens/smart_journey_screen.dart` | Create | Main screen — loads progress, owns scroll view, assembles everything |
| `lib/features/smart_learning/screens/smart_learning_screen.dart` | Modify | Category row taps → SmartJourneyScreen |
| `lib/core/localization/strings.i18n.json` | Modify | 5 new keys |
| `lib/core/localization/strings_sv.i18n.json` | Modify | 5 new Swedish translations |
| `lib/core/localization/strings_en.g.dart` | Modify | Generated methods + flat map entries |
| `lib/core/localization/strings_sv.g.dart` | Modify | Generated override methods + flat map entries |
| `test/features/smart_learning/utils/journey_utils_test.dart` | Create | Unit tests for item building + locking logic |

---

## Task 1: Localization keys

**Files:**
- Modify: `lib/core/localization/strings.i18n.json`
- Modify: `lib/core/localization/strings_sv.i18n.json`
- Modify: `lib/core/localization/strings_en.g.dart`
- Modify: `lib/core/localization/strings_sv.g.dart`

- [ ] **Step 1: Add keys to EN JSON**

In `strings.i18n.json`, before the closing `}`, add (after `smart_exit_body`):

```json
  "smart_journey_goal_label": "Full Category Exam",
  "smart_journey_goal_locked": "Complete all parts to unlock",
  "smart_journey_goal_ready": "Ready!",
  "smart_journey_you_are_here": "You're here",
  "smart_journey_full_review": "Full Mistakes Review"
```

- [ ] **Step 2: Add keys to SV JSON**

In `strings_sv.i18n.json`, before the closing `}`:

```json
  "smart_journey_goal_label": "Fullständigt kategoriprov",
  "smart_journey_goal_locked": "Slutför alla delar för att låsa upp",
  "smart_journey_goal_ready": "Redo!",
  "smart_journey_you_are_here": "Du är här",
  "smart_journey_full_review": "Fullständig felgranskning"
```

- [ ] **Step 3: Add generated getters to strings_en.g.dart**

After the `smart_mastered_of` line in the Translations class body:

```dart
	String get smart_journey_goal_label => 'Full Category Exam';
	String get smart_journey_goal_locked => 'Complete all parts to unlock';
	String get smart_journey_goal_ready => 'Ready!';
	String get smart_journey_you_are_here => 'You\'re here';
	String get smart_journey_full_review => 'Full Mistakes Review';
```

And in the `_flatMapFunction` switch, after the `smart_mastered_of` case:

```dart
			case 'smart_journey_goal_label': return 'Full Category Exam';
			case 'smart_journey_goal_locked': return 'Complete all parts to unlock';
			case 'smart_journey_goal_ready': return 'Ready!';
			case 'smart_journey_you_are_here': return 'You\'re here';
			case 'smart_journey_full_review': return 'Full Mistakes Review';
```

- [ ] **Step 4: Add generated overrides to strings_sv.g.dart**

After `smart_mastered_of` in the TranslationsSv class body:

```dart
	@override String get smart_journey_goal_label => 'Fullständigt kategoriprov';
	@override String get smart_journey_goal_locked => 'Slutför alla delar för att låsa upp';
	@override String get smart_journey_goal_ready => 'Redo!';
	@override String get smart_journey_you_are_here => 'Du är här';
	@override String get smart_journey_full_review => 'Fullständig felgranskning';
```

And in the SV `_flatMapFunction` switch, after the `smart_mastered_of` case:

```dart
			case 'smart_journey_goal_label': return 'Fullständigt kategoriprov';
			case 'smart_journey_goal_locked': return 'Slutför alla delar för att låsa upp';
			case 'smart_journey_goal_ready': return 'Redo!';
			case 'smart_journey_you_are_here': return 'Du är här';
			case 'smart_journey_full_review': return 'Fullständig felgranskning';
```

- [ ] **Step 5: Verify no analysis errors**

```bash
flutter analyze lib/core/localization/ --no-fatal-infos 2>&1 | tail -5
```
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/core/localization/
git commit -m "feat(i18n): add smart journey localization keys"
```

---

## Task 2: Journey item models + buildJourneyItems

**Files:**
- Create: `lib/features/smart_learning/utils/journey_utils.dart`
- Create: `test/features/smart_learning/utils/journey_utils_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/features/smart_learning/utils/journey_utils_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/journey_utils.dart';

SmartExamEntry _entry({
  required int testBcdId,
  required int questionCount,
  List<int>? chunkSizes,
}) =>
    SmartExamEntry(
      testBcdId: testBcdId,
      testName: 'Exam $testBcdId',
      categoryName: 'Cat',
      parentCategoryBcdId: 1,
      questionCount: questionCount,
      passScore: 70,
      timeLimit: 30,
      chunkSizes: chunkSizes ?? [10, 10],
    );

void main() {
  group('buildJourneyItems', () {
    test('first item is always GoalNode', () {
      final items = buildJourneyItems(
        entries: [_entry(testBcdId: 1, questionCount: 20)],
        passedCounts: {},
        combinedMastered: 0,
        combinedTotal: 20,
      );
      expect(items.first, isA<JourneyGoalNode>());
    });

    test('goal is locked when not all chunks passed', () {
      final items = buildJourneyItems(
        entries: [_entry(testBcdId: 1, questionCount: 20, chunkSizes: [10, 10])],
        passedCounts: {1: 1}, // only 1 of 2 chunks passed
        combinedMastered: 14,
        combinedTotal: 20,
      );
      expect((items.first as JourneyGoalNode).isUnlocked, isFalse);
    });

    test('goal is locked when mastery < 70% even if all chunks passed', () {
      final items = buildJourneyItems(
        entries: [_entry(testBcdId: 1, questionCount: 20, chunkSizes: [10, 10])],
        passedCounts: {1: 2}, // both chunks passed
        combinedMastered: 13, // 65% < 70%
        combinedTotal: 20,
      );
      expect((items.first as JourneyGoalNode).isUnlocked, isFalse);
    });

    test('goal is unlocked when all chunks passed AND mastery >= 70%', () {
      final items = buildJourneyItems(
        entries: [_entry(testBcdId: 1, questionCount: 20, chunkSizes: [10, 10])],
        passedCounts: {1: 2},
        combinedMastered: 14, // 70%
        combinedTotal: 20,
      );
      expect((items.first as JourneyGoalNode).isUnlocked, isTrue);
    });

    test('section labels appear once per exam in reverse order', () {
      final items = buildJourneyItems(
        entries: [
          _entry(testBcdId: 1, questionCount: 10, chunkSizes: [10]),
          _entry(testBcdId: 2, questionCount: 10, chunkSizes: [10]),
        ],
        passedCounts: {},
        combinedMastered: 0,
        combinedTotal: 20,
      );
      final labels = items.whereType<JourneySectionLabel>().toList();
      expect(labels.length, 2);
      // Last exam (testBcdId 2) comes first (near goal at top)
      expect(labels[0].examName, 'Exam 2');
      expect(labels[1].examName, 'Exam 1');
    });

    test('first exam chunk 0 is active when nothing passed', () {
      final items = buildJourneyItems(
        entries: [_entry(testBcdId: 1, questionCount: 20, chunkSizes: [10, 10])],
        passedCounts: {1: 0},
        combinedMastered: 0,
        combinedTotal: 20,
      );
      final nodes = items.whereType<JourneyStageNode>().toList();
      // Nodes are in reverse chunk order within each section (last chunk near top)
      // So nodes[0] = chunk 1 (last), nodes[1] = chunk 0 (first/active)
      final activeNode = nodes.firstWhere((n) => n.isActive);
      expect(activeNode.chunkIndex, 0);
      expect(activeNode.entry.testBcdId, 1);
    });

    test('second exam is fully locked when first exam not complete', () {
      final items = buildJourneyItems(
        entries: [
          _entry(testBcdId: 1, questionCount: 20, chunkSizes: [10, 10]),
          _entry(testBcdId: 2, questionCount: 10, chunkSizes: [10]),
        ],
        passedCounts: {1: 1, 2: 0}, // exam 1 has 1/2 passed
        combinedMastered: 0,
        combinedTotal: 30,
      );
      final exam2Nodes = items
          .whereType<JourneyStageNode>()
          .where((n) => n.entry.testBcdId == 2)
          .toList();
      expect(exam2Nodes.every((n) => n.isLocked), isTrue);
    });

    test('second exam unlocks when first exam fully passed', () {
      final items = buildJourneyItems(
        entries: [
          _entry(testBcdId: 1, questionCount: 20, chunkSizes: [10, 10]),
          _entry(testBcdId: 2, questionCount: 10, chunkSizes: [10]),
        ],
        passedCounts: {1: 2, 2: 0}, // exam 1 fully passed
        combinedMastered: 0,
        combinedTotal: 30,
      );
      final exam2Nodes = items
          .whereType<JourneyStageNode>()
          .where((n) => n.entry.testBcdId == 2)
          .toList();
      expect(exam2Nodes.any((n) => n.isActive), isTrue);
    });

    test('passed chunks are marked isPassed', () {
      final items = buildJourneyItems(
        entries: [_entry(testBcdId: 1, questionCount: 20, chunkSizes: [10, 10])],
        passedCounts: {1: 1},
        combinedMastered: 0,
        combinedTotal: 20,
      );
      final nodes = items.whereType<JourneyStageNode>()
          .where((n) => n.entry.testBcdId == 1)
          .toList();
      final passedNodes = nodes.where((n) => n.isPassed).toList();
      expect(passedNodes.length, 1);
      expect(passedNodes.first.chunkIndex, 0);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/features/smart_learning/utils/journey_utils_test.dart 2>&1 | tail -10
```
Expected: error — `journey_utils.dart` does not exist yet.

- [ ] **Step 3: Create journey_utils.dart**

Create `lib/features/smart_learning/utils/journey_utils.dart`:

```dart
import 'dart:ui';

import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';

// ── Journey item types ─────────────────────────────────────────────────────

sealed class JourneyItem {}

class JourneyGoalNode extends JourneyItem {
  final bool isUnlocked;
  JourneyGoalNode({required this.isUnlocked});
}

class JourneySectionLabel extends JourneyItem {
  final String examName;
  JourneySectionLabel(this.examName);
}

class JourneyStageNode extends JourneyItem {
  final SmartExamEntry entry;
  final int chunkIndex;
  final bool isPassed;
  final bool isActive;
  final bool isLocked;

  JourneyStageNode({
    required this.entry,
    required this.chunkIndex,
    required this.isPassed,
    required this.isActive,
    required this.isLocked,
  });
}

// ── Item list builder ──────────────────────────────────────────────────────

/// Builds the ordered display list for SmartJourneyScreen.
///
/// Layout (index 0 = top of screen = near goal):
///   [GoalNode, SectionLabel(lastExam), lastExamChunks..., ..., SectionLabel(firstExam), firstExamChunks...]
///
/// Within each exam, chunks are in REVERSE order (last chunk near top,
/// first chunk near bottom) so progression moves upward toward the goal.
List<JourneyItem> buildJourneyItems({
  required List<SmartExamEntry> entries,
  required Map<int, int> passedCounts,
  required int combinedMastered,
  required int combinedTotal,
}) {
  final allChunksDone = entries.every(
    (e) => (passedCounts[e.testBcdId] ?? 0) >= e.chunkSizes.length,
  );
  final masteryOk =
      combinedTotal == 0 || combinedMastered / combinedTotal >= 0.70;

  final items = <JourneyItem>[
    JourneyGoalNode(isUnlocked: allChunksDone && masteryOk),
  ];

  // Exams in reverse order — last exam is closest to goal (top).
  for (int i = entries.length - 1; i >= 0; i--) {
    final entry = entries[i];
    final passed = passedCounts[entry.testBcdId] ?? 0;

    // Exam i is unlocked when exam i-1 is fully complete (or it is the first exam).
    final examUnlocked = i == 0 ||
        (passedCounts[entries[i - 1].testBcdId] ?? 0) >=
            entries[i - 1].chunkSizes.length;

    items.add(JourneySectionLabel(entry.testName));

    // Chunks in reverse within the exam (last chunk near top of section).
    for (int j = entry.chunkSizes.length - 1; j >= 0; j--) {
      items.add(JourneyStageNode(
        entry: entry,
        chunkIndex: j,
        isPassed: examUnlocked && j < passed,
        isActive: examUnlocked && j == passed,
        isLocked: !examUnlocked || j > passed,
      ));
    }
  }

  return items;
}

// ── Layout constants ───────────────────────────────────────────────────────

const double kJourneyTopPadding = 80.0;
const double kJourneyGoalHeight = 150.0; // hexagon node + label text
const double kJourneyNodeSpacingY = 85.0;
const double kJourneySectionLabelHeight = 60.0;
const double kJourneyBottomPadding = 120.0;

const double kLeftFrac = 0.18;
const double kCenterFrac = 0.50;
const double kRightFrac = 0.82;

double _zigzagX(int nodeSeq, double screenWidth) {
  final group = nodeSeq ~/ 3;
  final posInGroup = nodeSeq % 3;
  final isLTR = group.isEven;
  if (posInGroup == 0) return screenWidth * (isLTR ? kLeftFrac : kRightFrac);
  if (posInGroup == 1) return screenWidth * kCenterFrac;
  return screenWidth * (isLTR ? kRightFrac : kLeftFrac);
}

// ── Position helpers ───────────────────────────────────────────────────────

/// Returns `(item, centre-offset)` for every non-SectionLabel item in [items].
/// Call once per build; cache the result.
List<(JourneyItem, Offset)> computeNodeOffsets(
    double screenWidth, List<JourneyItem> items) {
  final result = <(JourneyItem, Offset)>[];
  double y = kJourneyTopPadding;
  int nodeSeq = 0; // counts only StageNodes (not GoalNode)

  for (final item in items) {
    if (item is JourneySectionLabel) {
      y += kJourneySectionLabelHeight;
    } else if (item is JourneyGoalNode) {
      result.add((item, Offset(screenWidth / 2, y + kJourneyGoalHeight / 2)));
      y += kJourneyGoalHeight;
    } else {
      // JourneyStageNode
      result.add((item, Offset(_zigzagX(nodeSeq, screenWidth), y)));
      y += kJourneyNodeSpacingY;
      nodeSeq++;
    }
  }
  return result;
}

/// Returns `(topY, examName)` for every SectionLabel in [items].
List<(double, String)> computeSectionLabelOffsets(List<JourneyItem> items) {
  final result = <(double, String)>[];
  double y = kJourneyTopPadding;

  for (final item in items) {
    if (item is JourneyGoalNode) {
      y += kJourneyGoalHeight;
    } else if (item is JourneySectionLabel) {
      result.add((y, item.examName));
      y += kJourneySectionLabelHeight;
    } else {
      y += kJourneyNodeSpacingY;
    }
  }
  return result;
}

/// Total pixel height required to render all items.
double computeTotalHeight(List<JourneyItem> items) {
  double y = kJourneyTopPadding;
  for (final item in items) {
    if (item is JourneyGoalNode) {
      y += kJourneyGoalHeight;
    } else if (item is JourneySectionLabel) {
      y += kJourneySectionLabelHeight;
    } else {
      y += kJourneyNodeSpacingY;
    }
  }
  return y + kJourneyBottomPadding;
}
```

- [ ] **Step 4: Run tests — expect all pass**

```bash
flutter test test/features/smart_learning/utils/journey_utils_test.dart -v 2>&1 | tail -20
```
Expected: all 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/smart_learning/utils/journey_utils.dart \
        test/features/smart_learning/utils/journey_utils_test.dart
git commit -m "feat(smart-journey): journey item models + locking logic + tests"
```

---

## Task 3: JourneyPathPainter

**Files:**
- Create: `lib/features/smart_learning/widgets/journey_path_painter.dart`

- [ ] **Step 1: Create the painter**

Create `lib/features/smart_learning/widgets/journey_path_painter.dart`:

```dart
import 'package:flutter/material.dart';

/// Draws a smooth bezier snake path through [nodePositions] (centre offsets).
/// Positions must be in top-to-bottom order (goal first, first chunk last).
class JourneyPathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final Color pathColor;
  final double strokeWidth;

  const JourneyPathPainter({
    required this.nodePositions,
    required this.pathColor,
    this.strokeWidth = 7.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    final paint = Paint()
      ..color = pathColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(nodePositions.first.dx, nodePositions.first.dy);

    for (int i = 1; i < nodePositions.length; i++) {
      final prev = nodePositions[i - 1];
      final curr = nodePositions[i];
      final midY = (prev.dy + curr.dy) / 2;
      path.cubicTo(
        prev.dx, midY,
        curr.dx, midY,
        curr.dx, curr.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(JourneyPathPainter old) =>
      old.nodePositions != nodePositions ||
      old.pathColor != pathColor ||
      old.strokeWidth != strokeWidth;
}
```

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/features/smart_learning/widgets/journey_path_painter.dart 2>&1 | tail -5
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/smart_learning/widgets/journey_path_painter.dart
git commit -m "feat(smart-journey): add JourneyPathPainter"
```

---

## Task 4: Journey node widgets

**Files:**
- Create: `lib/features/smart_learning/widgets/journey_node_widget.dart`

- [ ] **Step 1: Create the widget file**

Create `lib/features/smart_learning/widgets/journey_node_widget.dart`:

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';

// ── Section pill ──────────────────────────────────────────────────────────

class JourneySectionPill extends StatelessWidget {
  final String name;
  const JourneySectionPill({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
      ),
    );
  }
}

// ── "Du är här" tooltip chip ──────────────────────────────────────────────

class JourneyYouAreHereChip extends StatelessWidget {
  const JourneyYouAreHereChip({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        t.smart_journey_you_are_here,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Circular chunk node ────────────────────────────────────────────────────

class JourneyChunkNode extends StatelessWidget {
  final bool isPassed;
  final bool isActive;
  final bool isLocked;
  final VoidCallback? onTap;

  static const double size = 64.0;

  const JourneyChunkNode({
    super.key,
    required this.isPassed,
    required this.isActive,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bg;
    final Color iconColor;
    final IconData icon;
    final double opacity;

    if (isPassed) {
      bg = Colors.green.shade500;
      iconColor = Colors.white;
      icon = Icons.check_rounded;
      opacity = 1.0;
    } else if (isActive) {
      bg = cs.primary;
      iconColor = Colors.white;
      icon = Icons.play_arrow_rounded;
      opacity = 1.0;
    } else {
      bg = Colors.white;
      iconColor = Colors.grey.shade400;
      icon = Icons.lock_outline_rounded;
      opacity = 0.65;
    }

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
      ),
    );
  }
}

// ── Hexagonal goal node ────────────────────────────────────────────────────

class JourneyGoalNodeWidget extends StatelessWidget {
  final bool isUnlocked;
  final VoidCallback? onTap;

  static const double hexSize = 90.0;

  const JourneyGoalNodeWidget({
    super.key,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.38,
      child: GestureDetector(
        onTap: isUnlocked ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(hexSize, hexSize),
              painter: _HexPainter(
                color: isUnlocked ? Colors.amber.shade600 : Colors.grey.shade400,
              ),
              child: SizedBox(
                width: hexSize,
                height: hexSize,
                child: Center(
                  child: Icon(
                    isUnlocked
                        ? Icons.emoji_events_rounded
                        : Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.smart_journey_goal_label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              isUnlocked
                  ? t.smart_journey_goal_ready
                  : t.smart_journey_goal_locked,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final Color color;
  const _HexPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * pi / 180;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.color != color;
}
```

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/features/smart_learning/widgets/journey_node_widget.dart 2>&1 | tail -5
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/smart_learning/widgets/journey_node_widget.dart
git commit -m "feat(smart-journey): add journey node widgets"
```

---

## Task 5: SmartJourneyScreen — scaffold + progress loading + path layout

**Files:**
- Create: `lib/features/smart_learning/screens/smart_journey_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/smart_learning/screens/smart_journey_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/bcd/providers/bcd_provider.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_category_mistakes_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_result_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_session_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/journey_utils.dart';
import 'package:taxi_exam_app/features/smart_learning/widgets/journey_node_widget.dart';
import 'package:taxi_exam_app/features/smart_learning/widgets/journey_path_painter.dart';

class SmartJourneyScreen extends StatefulWidget {
  final List<SmartExamEntry> entries;
  final String categoryName;

  const SmartJourneyScreen({
    super.key,
    required this.entries,
    required this.categoryName,
  });

  @override
  State<SmartJourneyScreen> createState() => _SmartJourneyScreenState();
}

class _SmartJourneyScreenState extends State<SmartJourneyScreen> {
  final _svc = SmartProgressService();
  final _provider = BcdProvider();
  final _scrollController = ScrollController();

  Map<int, int> _passedCounts = {};
  int _weakCount = 0;
  int _combinedMastered = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    // Fire all futures concurrently.
    final passedFs = {
      for (final e in widget.entries)
        e.testBcdId: _svc.activeSmartIndex(e.testBcdId, e.chunkSizes.length),
    };
    final weakF = _svc.weakQuestionCountForTests(
        widget.entries.map((e) => e.testBcdId).toList());
    final masteredFs = {
      for (final e in widget.entries)
        e.testBcdId: _svc.masteredQuestionCount(e.testBcdId, e.chunkSizes),
    };

    final passedCounts = <int, int>{};
    for (final kv in passedFs.entries) {
      passedCounts[kv.key] = await kv.value;
    }
    final weakCount = await weakF;
    int combinedMastered = 0;
    for (final kv in masteredFs.entries) {
      combinedMastered += await kv.value;
    }

    if (!mounted) return;
    setState(() {
      _passedCounts = passedCounts;
      _weakCount = weakCount;
      _combinedMastered = combinedMastered;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  int get _combinedTotal =>
      widget.entries.fold(0, (sum, e) => sum + e.questionCount);

  List<JourneyItem> get _items => buildJourneyItems(
        entries: widget.entries,
        passedCounts: _passedCounts,
        combinedMastered: _combinedMastered,
        combinedTotal: _combinedTotal,
      );

  void _scrollToActive() {
    if (!_scrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final nodeOffsets = computeNodeOffsets(screenWidth, _items);
    double? activeY;
    for (final (item, offset) in nodeOffsets) {
      if (item is JourneyStageNode && item.isActive) {
        activeY = offset.dy;
        break;
      }
    }
    if (activeY == null) return;
    final viewportHeight = MediaQuery.of(context).size.height;
    final stickyHeight = _weakCount > 0 ? 72.0 : 0.0;
    final target = (activeY - (viewportHeight - stickyHeight) / 2)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _onNodeTap(JourneyStageNode node) {
    if (node.isLocked) {
      showAppSnackBar(Translations.of(context).smart_full_exam_locked);
      return;
    }
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => SmartSessionScreen(
          entry: node.entry,
          chunkIndex: node.chunkIndex,
          isMistakesMode: false,
        ),
      ),
    ).then((_) => _load());
  }

  void _onGoalTap(JourneyGoalNode goal) {
    if (!goal.isUnlocked) return;
    _showFullExamSheet();
  }

  void _showFullExamSheet() {
    final t = Translations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.smart_journey_goal_label,
              style: Theme.of(ctx)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _launchFullExam(timed: false);
              },
              child: Text(t.smart_practice_mode),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _launchFullExam(timed: true);
              },
              child: Text(t.smart_timed_mode),
            ),
          ],
        ),
      ),
    );
  }

  // Full Category Exam launch is implemented in Task 6.
  Future<void> _launchFullExam({required bool timed}) async {}

  void _openMistakes() async {
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => SmartCategoryMistakesScreen(
          categoryName: widget.categoryName,
          entries: widget.entries,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          widget.categoryName,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(
                builder: (_, constraints) => _buildScrollView(
                    context, cs, constraints.maxWidth),
              ),
            ),
    );
  }

  Widget _buildScrollView(BuildContext context, ColorScheme cs, double width) {
    final items = _items;
    final nodeOffsets = computeNodeOffsets(width, items);
    final labelOffsets = computeSectionLabelOffsets(items);
    final totalHeight = computeTotalHeight(items);

    // Extract just the Offset list for the painter (all node positions).
    final pathPositions = nodeOffsets.map((e) => e.$2).toList();

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Sticky Train Mistakes card.
        SliverPersistentHeader(
          pinned: true,
          delegate: _TrainMistakesDelegate(
            weakCount: _weakCount,
            onTap: _openMistakes,
          ),
        ),
        // Journey path.
        SliverToBoxAdapter(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Snake path.
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: JourneyPathPainter(
                        nodePositions: pathPositions,
                        pathColor: cs.outline.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),

                // Section label pills.
                for (final (y, name) in labelOffsets)
                  Positioned(
                    top: y + 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: JourneySectionPill(name: name),
                    ),
                  ),

                // Node widgets.
                for (final (item, offset) in nodeOffsets)
                  if (item is JourneyGoalNode)
                    Positioned(
                      left: offset.dx - JourneyGoalNodeWidget.hexSize / 2,
                      top: offset.dy - JourneyGoalNodeWidget.hexSize / 2,
                      child: JourneyGoalNodeWidget(
                        isUnlocked: item.isUnlocked,
                        onTap: () => _onGoalTap(item),
                      ),
                    )
                  else if (item is JourneyStageNode) ...[
                    Positioned(
                      left: offset.dx - JourneyChunkNode.size / 2,
                      top: offset.dy - JourneyChunkNode.size / 2,
                      child: JourneyChunkNode(
                        isPassed: item.isPassed,
                        isActive: item.isActive,
                        isLocked: item.isLocked,
                        onTap: () => _onNodeTap(item),
                      ),
                    ),
                    if (item.isActive)
                      Positioned(
                        left: offset.dx - 50,
                        top: offset.dy - JourneyChunkNode.size / 2 - 30,
                        child: const JourneyYouAreHereChip(),
                      ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Train Mistakes sticky header ───────────────────────────────────────────

class _TrainMistakesDelegate extends SliverPersistentHeaderDelegate {
  final int weakCount;
  final VoidCallback onTap;

  static const double _cardHeight = 72.0;

  const _TrainMistakesDelegate({
    required this.weakCount,
    required this.onTap,
  });

  @override
  double get minExtent => weakCount > 0 ? _cardHeight : 0.0;

  @override
  double get maxExtent => weakCount > 0 ? _cardHeight : 0.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (weakCount == 0) return const SizedBox.shrink();
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final questionLabel = weakCount == 1
        ? t.smart_category_question
        : t.smart_category_questions;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.smart_category_mistakes_subtitle(
                      count: weakCount,
                      questionLabel: questionLabel,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: cs.error.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TrainMistakesDelegate old) =>
      old.weakCount != weakCount;
}
```

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/features/smart_learning/screens/smart_journey_screen.dart 2>&1 | tail -5
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/smart_learning/screens/smart_journey_screen.dart
git commit -m "feat(smart-journey): add SmartJourneyScreen scaffold + path layout"
```

---

## Task 6: Full Category Exam session

**Files:**
- Modify: `lib/features/smart_learning/screens/smart_journey_screen.dart` (lines 120-121, the empty `_launchFullExam`)

- [ ] **Step 1: Replace the stub `_launchFullExam` with full implementation**

Find and replace the stub in `_SmartJourneyScreenState`:

```dart
  Future<void> _launchFullExam({required bool timed}) async {
    // Fetch all questions from every exam in the category.
    final allQuestions = <Question>[];
    final questionTestMap = <String, int>{};
    for (final entry in widget.entries) {
      try {
        final qs = await _provider.fetchChunkQuestions(entry.testBcdId);
        for (final q in qs) {
          questionTestMap[q.questionId] = entry.testBcdId;
        }
        allQuestions.addAll(qs);
      } catch (_) {
        // Skip exams that fail to load.
      }
    }

    if (!mounted) return;

    if (allQuestions.isEmpty) {
      showAppSnackBar(Translations.of(context).bcd_no_questions);
      return;
    }

    allQuestions.shuffle(Random());

    final primaryEntry = widget.entries.reduce(
        (a, b) => a.questionCount >= b.questionCount ? a : b);
    final timeLimit = timed
        ? widget.entries.fold(0, (sum, e) => sum + e.timeLimit)
        : 0;

    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => SmartTestScreen(
          initialQuestions: allQuestions,
          passScorePercent: primaryEntry.passScore.toDouble(),
          testName: widget.categoryName,
          licenceId: '',
          categoryId: '',
          bcdCategoryId: primaryEntry.parentCategoryBcdId,
          bcdTestId: primaryEntry.testBcdId,
          onComplete: (hasPassed, finalResults) async {
            // Record results per-exam.
            final resultsByTest = <int, Map<String, bool>>{};
            for (final kv in finalResults.entries) {
              final testId = questionTestMap[kv.key];
              if (testId == null) continue;
              resultsByTest.putIfAbsent(testId, () => {})[kv.key] = kv.value;
            }
            for (final kv in resultsByTest.entries) {
              await _svc.recordSessionResults(kv.key, kv.value);
            }
            final mastered = await _svc.masteredQuestionCount(
                primaryEntry.testBcdId, primaryEntry.chunkSizes);
            final correct = finalResults.values.where((v) => v).length;
            return SmartResultScreen(
              entry: primaryEntry,
              chunkIndex: -1,
              isMistakesMode: true,
              hasPassed: hasPassed,
              correct: correct,
              total: finalResults.length,
              masteredCount: mastered,
            );
          },
        ),
      ),
    ).then((_) => _load());
  }
```

Also add the missing imports at the top of the file:

```dart
import 'dart:math';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_test_screen.dart';
```

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/features/smart_learning/screens/smart_journey_screen.dart 2>&1 | tail -5
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/smart_learning/screens/smart_journey_screen.dart
git commit -m "feat(smart-journey): Full Category Exam session with per-exam result recording"
```

---

## Task 7: Wire navigation in SmartLearningScreen

**Files:**
- Modify: `lib/features/smart_learning/screens/smart_learning_screen.dart`

- [ ] **Step 1: Add import for SmartJourneyScreen**

At the top of `smart_learning_screen.dart`, add:

```dart
import 'package:taxi_exam_app/features/smart_learning/screens/smart_journey_screen.dart';
```

- [ ] **Step 2: Replace category row onTap**

In `_buildCategoryList`, find the `onTap` of `_CategoryRow`:

```dart
onTap: () async {
  await Navigator.push(
    context,
    AppPageRoute(
      builder: (_) => SmartLearningScreen(
        examBcdId: widget.examBcdId,
        categoryFilter: catName,
      ),
    ),
  );
  _load();
},
```

Replace with:

```dart
onTap: () async {
  await Navigator.push(
    context,
    AppPageRoute(
      builder: (_) => SmartJourneyScreen(
        entries: catEntries,
        categoryName: catName,
      ),
    ),
  );
  _load();
},
```

- [ ] **Step 3: Replace exam row onTap in _buildTestList**

In `_buildTestList`, find the `onTap` of `_ExamRow`:

```dart
onTap: () async {
  await Navigator.push(
    context,
    AppPageRoute(
      builder: (_) => SmartExamScreen(entry: entry),
    ),
  );
  _load();
},
```

Replace with:

```dart
onTap: () async {
  await Navigator.push(
    context,
    AppPageRoute(
      builder: (_) => SmartJourneyScreen(
        entries: [entry],
        categoryName: entry.testName,
      ),
    ),
  );
  _load();
},
```

This handles the case where a sub-category has only one exam — it still opens `SmartJourneyScreen` (with one section).

- [ ] **Step 4: Verify analysis**

```bash
flutter analyze lib/features/smart_learning/screens/smart_learning_screen.dart 2>&1 | tail -5
```
Expected: `No issues found!`

- [ ] **Step 5: Run all smart-learning tests**

```bash
flutter test test/features/smart_learning/ -v 2>&1 | tail -15
```
Expected: all tests PASS.

- [ ] **Step 6: Full analysis**

```bash
flutter analyze lib/features/smart_learning/ lib/core/localization/ --no-fatal-infos 2>&1 | tail -5
```
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/features/smart_learning/screens/smart_learning_screen.dart
git commit -m "feat(smart-journey): wire SmartJourneyScreen into navigation"
```
