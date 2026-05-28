# In-App Review — Design Spec
_Date: 2026-05-28_

## Overview

Prompt users for an in-app store review at two points:
1. **Once ever** — immediately after completing their first exam (pass or fail).
2. **Periodically** — after every random N distinct usage days, where N is drawn from `[3, 5, 7]`.

Both triggers use the native OS review APIs via the `in_app_review` Flutter package. The OS silently rate-limits actual dialog display; our job is to call the API at the right moments and let the platform decide.

---

## Package

Add to `pubspec.yaml`:

```yaml
in_app_review: ^2.0.9
```

- **Android**: Google Play In-App Review API — native bottom sheet, no browser redirect. Requires the app to be published on Google Play (test on a real device with a Play Store install).
- **iOS**: `SKStoreReviewController.requestReview()` — native star-rating dialog. Requires the app to be on the App Store for the dialog to appear in production.

No platform-specific setup (AndroidManifest or Info.plist changes) is required beyond the package itself.

---

## Service: `AppReviewService`

**Location:** `lib/core/services/app_review_service.dart`

Singleton pattern matching existing services (`AnalyticsService`, `IapService`).

### SharedPreferences Keys

| Key | Type | Purpose |
|---|---|---|
| `review_first_exam_shown` | `bool` | `true` once the one-time post-exam prompt has fired. Never resets. |
| `review_last_open_date` | `String` | Last date the app was opened (`yyyy-MM-dd`). Used to detect a new distinct usage day. |
| `review_usage_day_count` | `int` | Running count of distinct calendar days the app has been opened. |
| `review_last_prompted_day_count` | `int` | Value of `review_usage_day_count` when the last periodic prompt fired. Starts at `0`. |
| `review_next_threshold` | `int` | Random pick from `[3, 5, 7]`. Set on first launch, re-randomised after each periodic prompt fires. |

### Public API

#### `Future<void> recordOpenAndMaybeRequest()`

Called from `SplashScreen._run()` after the existing SharedPreferences block.

Logic:
1. Get today as `yyyy-MM-dd` string.
2. If `review_last_open_date != today`: increment `review_usage_day_count`, save today as `review_last_open_date`.
3. If `review_next_threshold` is absent (first launch), write a random pick from `[3, 5, 7]` before continuing.
4. Compute `delta = review_usage_day_count - review_last_prompted_day_count`.
5. If `delta >= review_next_threshold`:
   - Call `InAppReview.instance.requestReview()`.
   - Set `review_last_prompted_day_count = review_usage_day_count`.
   - Pick a new random threshold from `[3, 5, 7]` and save to `review_next_threshold`.
   - (The old threshold value is discarded; the new random pick governs the next interval.)

#### `Future<void> maybeRequestAfterExam()`

Called from `ResultScreen.initState()` after the score is computed.

Logic:
1. Read `review_first_exam_shown`.
2. If `false`: call `InAppReview.instance.requestReview()`, set `review_first_exam_shown = true`.

### Error Handling

Both methods wrap all logic in a `try/catch` that silently swallows exceptions. A review failure must never surface to the user or cause a crash.

---

## Screen Changes

### `SplashScreen` (`lib/features/splash/splash_screen.dart`)

In `_run()`, after the existing `SharedPreferences.getInstance()` block, add:

```dart
await AppReviewService.instance.recordOpenAndMaybeRequest();
```

### `ResultScreen` (`lib/features/tests/result_screen.dart`)

In `initState()`, after the score computation, add:

```dart
AppReviewService.instance.maybeRequestAfterExam();
// fire-and-forget, no await needed
```

---

## Trigger Independence

The two triggers are independent:
- The post-exam prompt fires at most once on a device (flag-gated).
- The periodic prompt is driven solely by usage-day count; it doesn't reset or interact with the exam prompt.
- Both can theoretically fire within the same install, but not within the same session (exam prompt only fires on first-ever exam; by then the day-count threshold hasn't been reached yet on day 1).

---

## Testing Notes

- On Android: must test on a real device with an app installed from Play Store (internal testing track works). The review dialog won't appear in debug builds from Android Studio.
- On iOS: must test on a real device. In simulator, `requestReview()` is a no-op.
- For local verification of logic: read SharedPreferences keys directly and assert they change correctly.
