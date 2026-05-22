# Pull-to-Refresh Haptic Tick Feedback

**Date:** 2026-05-22  
**Status:** Approved

---

## Context

Users pull down to refresh on multiple screens in TaxiQuiz. The refresh indicator is already visible, but there is no tactile feedback during the drag. The goal is to add incremental haptic ticks as the user pulls down — a ratchet/notch feel — so each segment of drag produces a small vibration. This matches the pattern seen in premium iOS and Android apps. The existing loading progress UI stays unchanged.

---

## Scope

All screens that use `AdaptiveRefreshIndicator` (7 screens):
- Dashboard (`dashboard_body.dart`)
- BCD Licences (`bcd_licences_screen.dart`)
- BCD Traffic Signs (`bcd_traffic_signs_screen.dart`)
- BCD Subscriptions (`bcd_subscriptions_screen.dart`)
- Licences/Test Options (`licences_screen.dart`)
- Stats (`stats_screen.dart`)

Home screen (`home_screen.dart`) uses a plain `RefreshIndicator` directly and is excluded from this change (it can be added as a follow-up).

---

## Design

### Single file change

Only `lib/core/widgets/adaptive_refresh_indicator.dart` is modified.

### Widget conversion

`AdaptiveRefreshIndicator` converts from `StatelessWidget` to `StatefulWidget` to hold drag tracking state.

### State variables

```dart
double _totalOverscroll = 0.0;       // accumulated drag pixels since last release
double _lastHapticThreshold = 0.0;   // _totalOverscroll at last haptic fire
DateTime? _lastHapticTime;           // for minimum interval guard
```

### Constants

```dart
static const double _hapticTickInterval = 12.0; // pixels between ticks
static const Duration _minHapticInterval = Duration(milliseconds: 30); // max ~33/sec
```

### NotificationListener

Both the iOS and Android scroll views are wrapped with:

```dart
NotificationListener<ScrollNotification>(
  onNotification: _handleScrollNotification,
  child: /* CustomScrollView or RefreshIndicator */,
)
```

The handler returns `false` so notifications continue propagating to `RefreshIndicator` and `CupertinoSliverRefreshControl` normally — no interference with existing refresh behaviour.

### Handler logic

```dart
bool _handleScrollNotification(ScrollNotification notification) {
  if (notification is OverscrollNotification && notification.overscroll < 0) {
    _totalOverscroll += notification.overscroll.abs();
    final now = DateTime.now();
    final gapOk = _lastHapticTime == null ||
        now.difference(_lastHapticTime!) >= _minHapticInterval;
    if (gapOk && _totalOverscroll - _lastHapticThreshold >= _hapticTickInterval) {
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
```

### Platform behaviour

| Platform | Haptic call | Notes |
|----------|------------|-------|
| iOS      | `HapticFeedback.lightImpact()` | Uses UIImpactFeedbackGenerator |
| Android  | `HapticFeedback.lightImpact()` | Maps to EFFECT_TICK on Android 8+ |
| Web      | No-op (gracefully ignored by Flutter) | |

No new packages required. Uses Flutter's built-in `HapticFeedback` from `flutter/services.dart` (already imported in the file).

---

## What stays unchanged

- The existing visual refresh indicator (spinner/Cupertino animation) is fully preserved
- `onRefresh` callbacks are untouched
- All screen-level refresh logic is untouched
- No changes to `NavigationFeedbackService`

---

## Verification

1. Run on a physical iOS device: pull down on Dashboard — feel uniform small ticks during drag, no ticks after release, spinner still appears and completes normally.
2. Run on a physical Android device: same test.
3. Pull very quickly — confirm no performance jank (haptic rate stays bounded by 30ms guard).
4. Pull partially and release before trigger threshold — confirm no crash, counters reset cleanly.
5. Navigate to Stats, Licences, BCD screens and confirm haptic ticks work on all of them.
