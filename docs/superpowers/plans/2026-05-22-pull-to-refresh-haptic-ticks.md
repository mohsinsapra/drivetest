# Pull-to-Refresh Haptic Tick Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add uniform haptic tick feedback during pull-to-refresh drag on all screens that use `AdaptiveRefreshIndicator`, so users feel a small vibration every ~12px of drag.

**Architecture:** Convert `AdaptiveRefreshIndicator` from `StatelessWidget` to `StatefulWidget`, wrap both the iOS and Android scroll views with a `NotificationListener<ScrollNotification>`, and fire `HapticFeedback.lightImpact()` at a fixed pixel interval during overscroll. The handler returns `false` so existing refresh behaviour is unaffected.

**Tech Stack:** Flutter, `flutter/services.dart` (`HapticFeedback`), `flutter/material.dart`, `flutter/cupertino.dart`

---

## Files

| Action | Path |
|--------|------|
| Modify | `lib/core/widgets/adaptive_refresh_indicator.dart` |
| Create | `test/core/widgets/adaptive_refresh_indicator_test.dart` |

---

### Task 1: Write the failing widget test

**Files:**
- Create: `test/core/widgets/adaptive_refresh_indicator_test.dart`

- [ ] **Step 1: Create the test file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';

void main() {
  group('AdaptiveRefreshIndicator haptic ticks', () {
    final List<MethodCall> hapticCalls = [];

    setUp(() {
      hapticCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('fires haptic ticks during overscroll drag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: AdaptiveRefreshIndicator(
              onRefresh: () async {},
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [const SizedBox(height: 2000)],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Drag down 80px to simulate pull-to-refresh gesture
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pump();

      // Should have fired at least one haptic tick (80px / 12px interval = ~6)
      expect(
        hapticCalls.where((c) => c.arguments == 'HapticFeedbackType.lightImpact'),
        isNotEmpty,
      );
    });

    testWidgets('does not fire haptic when scrolling down (not overscroll)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: AdaptiveRefreshIndicator(
              onRefresh: () async {},
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    List.generate(50, (_) => const SizedBox(height: 60)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Scroll down (not overscroll at top)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pump();

      expect(
        hapticCalls.where((c) => c.arguments == 'HapticFeedbackType.lightImpact'),
        isEmpty,
      );
    });

    testWidgets('resets counters after release so next drag fires fresh ticks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: AdaptiveRefreshIndicator(
              onRefresh: () async {},
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [const SizedBox(height: 2000)],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // First drag
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pump();
      final firstCount = hapticCalls.length;
      expect(firstCount, greaterThan(0));

      hapticCalls.clear();

      // Second drag after release — should fire again from scratch
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pump();
      expect(hapticCalls.length, greaterThan(0));
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/muhammadmohsin/Documents/Learning/TAXI/App/taxi_exam_app
flutter test test/core/widgets/adaptive_refresh_indicator_test.dart -v
```

Expected: FAIL — `AdaptiveRefreshIndicator` exists but has no haptic logic yet, so `hapticCalls` will be empty.

---

### Task 2: Implement haptic ticks in AdaptiveRefreshIndicator

**Files:**
- Modify: `lib/core/widgets/adaptive_refresh_indicator.dart`

- [ ] **Step 1: Replace the entire file with the new implementation**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pull-to-refresh that uses [CupertinoSliverRefreshControl] on iOS/web
/// and [RefreshIndicator] on Android. Fires light haptic ticks during drag.
class AdaptiveRefreshIndicator extends StatefulWidget {
  const AdaptiveRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.physics,
    this.controller,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  @override
  State<AdaptiveRefreshIndicator> createState() =>
      _AdaptiveRefreshIndicatorState();
}

class _AdaptiveRefreshIndicatorState extends State<AdaptiveRefreshIndicator> {
  static const double _hapticTickInterval = 12.0;
  static const Duration _minHapticInterval = Duration(milliseconds: 30);

  double _totalOverscroll = 0.0;
  double _lastHapticThreshold = 0.0;
  DateTime? _lastHapticTime;

  static bool _useCupertino(BuildContext context) =>
      kIsWeb || Theme.of(context).platform == TargetPlatform.iOS;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification && notification.overscroll < 0) {
      _totalOverscroll += notification.overscroll.abs();
      final now = DateTime.now();
      final gapOk = _lastHapticTime == null ||
          now.difference(_lastHapticTime!) >= _minHapticInterval;
      if (gapOk &&
          _totalOverscroll - _lastHapticThreshold >= _hapticTickInterval) {
        HapticFeedback.lightImpact();
        _lastHapticThreshold = _totalOverscroll;
        _lastHapticTime = now;
      }
    } else if (notification is ScrollEndNotification) {
      _totalOverscroll = 0.0;
      _lastHapticThreshold = 0.0;
      _lastHapticTime = null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final effectivePhysics = widget.physics ?? const AlwaysScrollableScrollPhysics();

    if (_useCupertino(context)) {
      return NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          controller: widget.controller,
          physics: effectivePhysics,
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: widget.onRefresh),
            ...widget.slivers,
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: CustomScrollView(
          controller: widget.controller,
          physics: effectivePhysics,
          slivers: widget.slivers,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run the tests to confirm they pass**

```bash
flutter test test/core/widgets/adaptive_refresh_indicator_test.dart -v
```

Expected: All 3 tests PASS.

- [ ] **Step 3: Run full test suite to confirm no regressions**

```bash
flutter test
```

Expected: All existing tests continue to pass.

- [ ] **Step 4: Commit**

```bash
git add lib/core/widgets/adaptive_refresh_indicator.dart \
        test/core/widgets/adaptive_refresh_indicator_test.dart
git commit -m "feat: add haptic tick feedback during pull-to-refresh drag"
```

---

### Task 3: Manual verification on device

- [ ] **Step 1: Run on iOS physical device**

```bash
flutter run --release
```

Navigate to Dashboard → pull down slowly → confirm:
- Small vibration ticks on each ~12px of drag
- Existing loading spinner still appears and completes
- No ticks when simply scrolling down through content
- Pulling and releasing before trigger threshold causes no crash

- [ ] **Step 2: Run on Android physical device**

Same test as Step 1 on an Android device. Confirm same behaviour.

- [ ] **Step 3: Verify all refresh screens**

Test pull-to-refresh haptic ticks on:
- [ ] Dashboard
- [ ] BCD Licences
- [ ] BCD Traffic Signs
- [ ] BCD Subscriptions
- [ ] Licences / Test Options screen
- [ ] Stats screen
