# In-App Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prompt users for a native store review after their first exam completion (once ever) and after every random 3/5/7 distinct usage days thereafter.

**Architecture:** A singleton `AppReviewService` in `lib/core/services/` wraps `InAppReview` and manages five `SharedPreferences` keys. `SplashScreen._run()` calls `recordOpenAndMaybeRequest()` on every launch; `ResultScreen.initState()` calls `maybeRequestAfterExam()` fire-and-forget.

**Tech Stack:** Flutter, `in_app_review ^2.0.9`, `shared_preferences ^2.5.3` (already in pubspec)

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `lib/core/services/app_review_service.dart` | All review logic, SharedPreferences state |
| Create | `test/core/services/app_review_service_test.dart` | Unit tests for the service |
| Modify | `pubspec.yaml` | Add `in_app_review` dependency |
| Modify | `lib/features/splash/splash_screen.dart` | Call `recordOpenAndMaybeRequest()` |
| Modify | `lib/features/tests/result_screen.dart` | Call `maybeRequestAfterExam()` |

---

## Task 1: Add the `in_app_review` package

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

Open `pubspec.yaml`. In the `dependencies:` block, after the `upgrader:` line, add:

```yaml
  in_app_review: ^2.0.9
```

- [ ] **Step 2: Fetch the package**

```bash
cd /Users/muhammadmohsin/Documents/Learning/TAXI/App/taxi_exam_app
flutter pub get
```

Expected: output ends with `Got dependencies!` and no errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add in_app_review package"
```

---

## Task 2: Write the `AppReviewService` with tests (TDD)

**Files:**
- Create: `test/core/services/app_review_service_test.dart`
- Create: `lib/core/services/app_review_service.dart`

### Step 2a — Write failing tests first

- [ ] **Step 1: Create the test file**

Create `test/core/services/app_review_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/services/app_review_service.dart';

// Minimal fake that records calls without hitting a platform channel.
class _FakeReview implements InAppReview {
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => requestCount++;

  @override
  Future<void> openStoreListing({String? appStoreId}) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('maybeRequestAfterExam', () {
    test('requests review and sets flag on first call', () async {
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.maybeRequestAfterExam();

      expect(fake.requestCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('review_first_exam_shown'), true);
    });

    test('does NOT request review if flag already set', () async {
      SharedPreferences.setMockInitialValues({
        'review_first_exam_shown': true,
      });
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.maybeRequestAfterExam();

      expect(fake.requestCount, 0);
    });
  });

  group('recordOpenAndMaybeRequest', () {
    test('increments usage day count on first open', () async {
      final svc = AppReviewService.forTest(_FakeReview());
      await svc.recordOpenAndMaybeRequest();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review_usage_day_count'), 1);
    });

    test('does not increment count when called twice same day', () async {
      final svc = AppReviewService.forTest(_FakeReview());
      await svc.recordOpenAndMaybeRequest();
      await svc.recordOpenAndMaybeRequest();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review_usage_day_count'), 1);
    });

    test('fires review when usage days reaches threshold', () async {
      // Set state as if threshold is 3 and 2 days already counted.
      SharedPreferences.setMockInitialValues({
        'review_usage_day_count': 2,
        'review_last_prompted_day_count': 0,
        'review_next_threshold': 3,
        // Use a past date so today counts as new day.
        'review_last_open_date': '2000-01-01',
      });
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.recordOpenAndMaybeRequest();

      // Day count is now 3, delta = 3 - 0 = 3 >= threshold 3 → fires.
      expect(fake.requestCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review_last_prompted_day_count'), 3);
      // New threshold must be one of [3, 5, 7].
      expect([3, 5, 7], contains(prefs.getInt('review_next_threshold')));
    });

    test('does NOT fire review when below threshold', () async {
      SharedPreferences.setMockInitialValues({
        'review_usage_day_count': 1,
        'review_last_prompted_day_count': 0,
        'review_next_threshold': 5,
        'review_last_open_date': '2000-01-01',
      });
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.recordOpenAndMaybeRequest();

      // Day count is now 2, delta = 2 - 0 = 2 < threshold 5 → no fire.
      expect(fake.requestCount, 0);
    });

    test('review does not propagate exceptions', () async {
      // Even if review throws, service must swallow it.
      final svc = AppReviewService.forTest(_ThrowingReview());
      await expectLater(svc.maybeRequestAfterExam(), completes);
    });
  });
}

class _ThrowingReview implements InAppReview {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> requestReview() async => throw Exception('platform error');
  @override
  Future<void> openStoreListing({String? appStoreId}) async {}
}
```

- [ ] **Step 2: Run the tests — expect them to FAIL (file doesn't exist yet)**

```bash
flutter test test/core/services/app_review_service_test.dart
```

Expected: compile error — `app_review_service.dart` not found.

### Step 2b — Implement the service

- [ ] **Step 3: Create `lib/core/services/app_review_service.dart`**

```dart
import 'dart:math';

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  static final AppReviewService instance =
      AppReviewService._internal(InAppReview.instance);

  AppReviewService._internal(this._review);

  /// Test-only constructor — injects a fake [InAppReview].
  factory AppReviewService.forTest(InAppReview review) =>
      AppReviewService._internal(review);

  final InAppReview _review;

  static const _keyFirstExamShown = 'review_first_exam_shown';
  static const _keyLastOpenDate = 'review_last_open_date';
  static const _keyUsageDayCount = 'review_usage_day_count';
  static const _keyLastPromptedDayCount = 'review_last_prompted_day_count';
  static const _keyNextThreshold = 'review_next_threshold';
  static const _thresholds = [3, 5, 7];

  /// Called from SplashScreen on every app open.
  Future<void> recordOpenAndMaybeRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _today();

      final lastOpenDate = prefs.getString(_keyLastOpenDate);
      int dayCount = prefs.getInt(_keyUsageDayCount) ?? 0;

      if (lastOpenDate != today) {
        dayCount++;
        await prefs.setInt(_keyUsageDayCount, dayCount);
        await prefs.setString(_keyLastOpenDate, today);
      }

      int threshold = prefs.getInt(_keyNextThreshold) ?? _randomThreshold();
      await prefs.setInt(_keyNextThreshold, threshold);

      final lastPrompted = prefs.getInt(_keyLastPromptedDayCount) ?? 0;
      if (dayCount - lastPrompted >= threshold) {
        await _request();
        await prefs.setInt(_keyLastPromptedDayCount, dayCount);
        await prefs.setInt(_keyNextThreshold, _randomThreshold());
      }
    } catch (_) {}
  }

  /// Called from ResultScreen after the first ever exam completion.
  Future<void> maybeRequestAfterExam() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyFirstExamShown) ?? false) return;
      await _request();
      await prefs.setBool(_keyFirstExamShown, true);
    } catch (_) {}
  }

  Future<void> _request() async {
    await _review.requestReview();
  }

  static int _randomThreshold() =>
      _thresholds[Random().nextInt(_thresholds.length)];

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 4: Run the tests — expect them to PASS**

```bash
flutter test test/core/services/app_review_service_test.dart
```

Expected: all tests pass, no failures.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/app_review_service.dart test/core/services/app_review_service_test.dart
git commit -m "feat: add AppReviewService with usage-day and post-exam triggers"
```

---

## Task 3: Wire into `SplashScreen`

**Files:**
- Modify: `lib/features/splash/splash_screen.dart`

- [ ] **Step 1: Add the import**

At the top of `lib/features/splash/splash_screen.dart`, add after the existing imports:

```dart
import 'package:taxi_exam_app/core/services/app_review_service.dart';
```

- [ ] **Step 2: Call the service after the SharedPreferences block**

In `_run()`, after the `try/catch` block that ends at line 122 (the block reading `onboarding_complete`), add:

```dart
    // Fire-and-forget: track distinct usage day, prompt for review if threshold met.
    unawaited(AppReviewService.instance.recordOpenAndMaybeRequest());
```

The surrounding context should look like:

```dart
    bool onboardingComplete = false;
    try {
      final results = await Future.wait([
        SharedPreferences.getInstance(),
        DioClient().reloadTokens(),
      ]);
      final prefs = results[0] as SharedPreferences;
      onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    } catch (_) {}

    // Fire-and-forget: track distinct usage day, prompt for review if threshold met.
    unawaited(AppReviewService.instance.recordOpenAndMaybeRequest());

    final hasTokens =
        DioClient().refreshToken != null && DioClient().accessToken != null;
```

- [ ] **Step 3: Add the `unawaited` import if not already present**

Check the top of the file for `dart:async`. If not present, add:

```dart
import 'dart:async';
```

- [ ] **Step 4: Verify the app still compiles**

```bash
flutter analyze lib/features/splash/splash_screen.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/splash/splash_screen.dart
git commit -m "feat: wire AppReviewService into SplashScreen"
```

---

## Task 4: Wire into `ResultScreen`

**Files:**
- Modify: `lib/features/tests/result_screen.dart`

- [ ] **Step 1: Add the import**

At the top of `lib/features/tests/result_screen.dart`, add after the existing imports:

```dart
import 'package:taxi_exam_app/core/services/app_review_service.dart';
```

- [ ] **Step 2: Call the service at the end of `initState()`**

In `initState()`, after `_ctrl.forward();` (line 56), add:

```dart
    // Fire-and-forget: request review after first-ever exam completion.
    AppReviewService.instance.maybeRequestAfterExam();
```

The surrounding context should look like:

```dart
  void initState() {
    super.initState();
    int c = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final sel = widget.userSelections[i];
      if (sel != null && sel == widget.questions[i].correctAnswer) c++;
    }
    _correct = c;
    _scorePercent =
        widget.questions.isEmpty ? 0 : (c / widget.questions.length) * 100;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: _scorePercent / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
    // Fire-and-forget: request review after first-ever exam completion.
    AppReviewService.instance.maybeRequestAfterExam();
  }
```

- [ ] **Step 3: Verify the app compiles**

```bash
flutter analyze lib/features/tests/result_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Run the full test suite to catch regressions**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tests/result_screen.dart
git commit -m "feat: wire AppReviewService into ResultScreen post-exam trigger"
```

---

## Testing Notes

- **Android**: Must test on a real device with an app installed from the Play Store (internal testing track works). The review dialog will not appear in debug builds from Android Studio/VS Code.
- **iOS**: Must test on a physical device. The dialog is a no-op in the iOS Simulator.
- **Manual verification of logic**: Read `SharedPreferences` keys via the service's test constructor or temporarily print values in `_run()` to confirm day counts and flags update correctly.
- To force the post-exam prompt: clear app data (or uninstall/reinstall) so `review_first_exam_shown` is absent, then complete any exam.
- To force the periodic prompt: set `review_usage_day_count` to `(review_last_prompted_day_count + review_next_threshold - 1)` via a debug build tool, then relaunch the app on a new calendar day.
