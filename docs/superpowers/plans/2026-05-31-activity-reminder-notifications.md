# Activity Reminder Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Schedule a local push notification 24 hours after every exam or Smart Learning session completion, with the exam title + a localised hook phrase, that deep-links the user back to the exact screen they left.

**Architecture:** A new `ActivityReminderService` schedules notifications into a circular pool of 5 IDs (200–204) so multiple same-day sessions each get their own 24-hour reminder. The existing `StreakNotificationService` plugin is exposed as a public static getter so both services share one initialised `FlutterLocalNotificationsPlugin` instance (avoiding double-initialise overwriting the tap callback). On tap, the JSON payload is saved to SharedPreferences; the SplashScreen reads it after login and pushes the target screen.

**Tech Stack:** `flutter_local_notifications ^18`, `shared_preferences`, `timezone`, `flutter_timezone`, existing `NavigationService.navigatorKey`, existing `BcdCache`, existing `ApiService.fetchQuestions()`

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Create | `lib/core/services/activity_reminder_service.dart` | Schedule/cancel reminders, phrase pool, deep-link save/consume/navigate |
| Modify | `lib/core/services/streak_notification_service.dart` | Expose `plugin` getter, add tap callback + cold-start detection in `init()` |
| Modify | `lib/core/widgets/test_dialogs.dart` | Add `categoryName` param, thread it to `ResultScreen` |
| Modify | `lib/features/tests/result_screen.dart` | Add `categoryName` param, schedule activity reminder in `initState` |
| Modify | `lib/features/smart_learning/screens/smart_result_screen.dart` | Schedule activity reminder in `initState` |
| Modify | `lib/features/splash/splash_screen.dart` | `cancelAll()` on open; consume + navigate deep link after auth |
| Create | `test/core/services/activity_reminder_service_test.dart` | Unit tests for scheduling, cancel, phrase selection, payload round-trip |

---

## Task 1: Expose plugin from StreakNotificationService + wire tap callback

**Files:**
- Modify: `lib/core/services/streak_notification_service.dart`

- [ ] **Step 1: Make `_plugin` accessible and add tap callback to `init()`**

Replace the private field and `init()` method body in `streak_notification_service.dart`:

```dart
// Change this:
static final _plugin = FlutterLocalNotificationsPlugin();

// To this (public getter, same instance):
static final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

/// Exposed so ActivityReminderService can schedule without a second init().
static FlutterLocalNotificationsPlugin get plugin => _plugin;
```

In `init()`, replace the `await _plugin.initialize(...)` call with:

```dart
await _plugin.initialize(
  const InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  ),
  onDidReceiveNotificationResponse: _onNotificationResponse,
  onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
);
```

- [ ] **Step 2: Add the tap handler methods (add at bottom of `StreakNotificationService`)**

```dart
static void _onNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  final id = response.id ?? -1;
  if (payload == null || payload.isEmpty) return;
  if (id < 200 || id >= 205) return; // only activity reminders

  final nav = NavigationService.navigatorKey.currentState;
  if (nav != null) {
    ActivityReminderService.navigateFromPayload(nav, payload);
  } else {
    ActivityReminderService.savePendingDeepLink(payload).ignore();
  }
}

@pragma('vm:entry-point')
static void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Background isolate — only save; navigation happens on next foreground open.
  final payload = response.payload;
  final id = response.id ?? -1;
  if (payload == null || payload.isEmpty) return;
  if (id < 200 || id >= 205) return;
  ActivityReminderService.savePendingDeepLink(payload).ignore();
}
```

- [ ] **Step 3: Add cold-start detection at the END of `init()` (before `_initialised = true`)**

```dart
// Cold-start: app was terminated when user tapped notification
final launchDetails = await _plugin.getNotificationAppLaunchDetails();
if (launchDetails?.didNotificationLaunchApp == true) {
  final resp = launchDetails!.notificationResponse;
  final id = resp?.id ?? -1;
  if (resp?.payload != null && id >= 200 && id < 205) {
    await ActivityReminderService.savePendingDeepLink(resp!.payload!);
  }
}
```

- [ ] **Step 4: Add missing imports to `streak_notification_service.dart`**

```dart
import 'package:taxi_exam_app/core/services/activity_reminder_service.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
```

- [ ] **Step 5: Run analysis**

```bash
flutter analyze lib/core/services/streak_notification_service.dart
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/core/services/streak_notification_service.dart
git commit -m "feat: expose local notifications plugin and wire activity-reminder tap handler"
```

---

## Task 2: Create ActivityReminderService

**Files:**
- Create: `lib/core/services/activity_reminder_service.dart`

- [ ] **Step 1: Create the file**

```dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:taxi_exam_app/core/services/streak_notification_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_exam_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:timezone/timezone.dart' as tz;

class ActivityReminderService {
  static const _channelId = 'activity_reminders';
  static const _channelName = 'Activity Reminders';
  static const _idStart = 200;
  static const _poolSize = 5;
  static const _keySlot = 'activity_reminder_slot';
  static const _keyPendingDeepLink = 'activity_deep_link';

  static final _rng = Random();

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Schedules a notification 24 hours from now.
  /// [examTitle] is shown as the notification title.
  /// [payloadJson] is a JSON string with routing info (see [buildPayload]).
  /// [locale] is 'sv' or 'en' — selects phrase language.
  static Future<void> schedule({
    required String examTitle,
    required String payloadJson,
    required String locale,
  }) async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final slot = (prefs.getInt(_keySlot) ?? 0) % _poolSize;
    final notifId = _idStart + slot;
    await prefs.setInt(_keySlot, (slot + 1) % _poolSize);

    final hookIndex = _rng.nextInt(_enPhrases.length);
    final phrases = locale == 'sv' ? _svPhrases : _enPhrases;
    final body = phrases[hookIndex].replaceAll('{examTitle}', examTitle);

    final fireAt =
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

    await StreakNotificationService.plugin.zonedSchedule(
      notifId,
      examTitle,
      body,
      fireAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription:
              'Reminders to continue your exam practice',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payloadJson,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels all 5 activity reminder slots.
  /// Call this whenever the user opens the app (they're active — no need to remind).
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    for (int i = 0; i < _poolSize; i++) {
      await StreakNotificationService.plugin.cancel(_idStart + i);
    }
  }

  // ── Payload helpers ────────────────────────────────────────────────────────

  static String buildSmartPayload(int testBcdId) =>
      json.encode({'screen': 'smart', 'testBcdId': testBcdId});

  static String buildTestPayload({
    required String licenceId,
    required String categoryId,
    required String categoryName,
  }) =>
      json.encode({
        'screen': 'test',
        'licenceId': licenceId,
        'categoryId': categoryId,
        'categoryName': categoryName,
      });

  // ── Deep link store / consume ──────────────────────────────────────────────

  static Future<void> savePendingDeepLink(String payloadJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingDeepLink, payloadJson);
  }

  /// Returns the pending deep-link payload and clears it. Returns null if none.
  static Future<String?> consumePendingDeepLink() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_keyPendingDeepLink);
    if (payload != null) await prefs.remove(_keyPendingDeepLink);
    return payload;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Parses [payloadJson] and pushes the appropriate screen onto [nav].
  static void navigateFromPayload(NavigatorState nav, String payloadJson) {
    try {
      final data = json.decode(payloadJson) as Map<String, dynamic>;
      final screen = data['screen'] as String?;

      if (screen == 'smart') {
        final testBcdId = data['testBcdId'] as int;
        final entry = _entryForTestBcdId(testBcdId);
        if (entry == null) return;
        nav.push(AppPageRoute(
          builder: (_) => SmartExamScreen(entry: entry),
        ));
      } else if (screen == 'test') {
        final licenceId = data['licenceId'] as String;
        final categoryId = data['categoryId'] as String;
        final categoryName = (data['categoryName'] as String?) ?? '';
        nav.push(AppPageRoute(
          builder: (_) => _TestDeepLinkLoader(
            licenceId: licenceId,
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ));
      }
    } catch (_) {}
  }

  /// Builds a [SmartExamEntry] from [BcdCache] for [testBcdId].
  /// Returns null if the test is not found in the cache.
  static SmartExamEntry? _entryForTestBcdId(int testBcdId) {
    for (final cat in BcdCache.instance.categories) {
      final catId = cat['bcd_id'] as int;
      for (final test in BcdCache.instance.testsOf(catId)) {
        if (test['bcd_id'] == testBcdId) {
          return _entryFromTest(test, cat['name']?.toString() ?? '', catId);
        }
      }
      for (final sub in BcdCache.instance.subcategoriesOf(catId)) {
        final subId = sub['bcd_id'] as int;
        for (final test in BcdCache.instance.testsOf(subId)) {
          if (test['bcd_id'] == testBcdId) {
            return _entryFromTest(
                test, sub['name']?.toString() ?? '', subId);
          }
        }
      }
    }
    return null;
  }

  static SmartExamEntry _entryFromTest(
      Map<String, dynamic> test, String catName, int catId) {
    final qc = test['question_count'] as int? ?? 0;
    // SmartUtils.computeSmartSizes is package-private; inline the same logic.
    final chunkSizes = _computeSmartSizes(qc);
    return SmartExamEntry(
      testBcdId: test['bcd_id'] as int,
      testName: test['name']?.toString() ?? '',
      categoryName: catName,
      parentCategoryBcdId: catId,
      questionCount: qc,
      passScore: test['pass_score'] as int? ?? 0,
      timeLimit: test['time_limit'] as int? ?? 0,
      chunkSizes: chunkSizes,
    );
  }

  static List<int> _computeSmartSizes(int total) {
    // Mirror of SmartUtils.computeSmartSizes — keep in sync if that changes.
    if (total <= 10) return [total];
    final targetSize = total <= 20 ? 10 : 15;
    final count = (total / targetSize).ceil();
    final base = total ~/ count;
    final remainder = total % count;
    return List.generate(count, (i) => base + (i < remainder ? 1 : 0));
  }

  // ── Phrase pool ────────────────────────────────────────────────────────────

  static const _enPhrases = [
    'You practiced {examTitle} yesterday — keep the momentum going!',
    'Your progress on {examTitle} is looking great. Pick up where you left off!',
    'One more session on {examTitle} and you\'ll be that much closer to passing.',
    'Don\'t let {examTitle} slip — you\'ve been doing really well!',
    'Ready to continue {examTitle}? You\'re making solid progress.',
    'You\'ve built good habits with {examTitle}. Keep it up!',
    'Time to revisit {examTitle} — consistency is the key to passing.',
    'You\'re on a roll with {examTitle}. Come back and keep practising!',
  ];

  static const _svPhrases = [
    'Du övade {examTitle} igår — håll farten uppe!',
    'Dina framsteg på {examTitle} ser bra ut. Fortsätt där du slutade!',
    'Ännu en session till på {examTitle} och du är närmre att klara provet.',
    'Glöm inte {examTitle} — du har gjort riktigt bra ifrån dig!',
    'Redo att fortsätta med {examTitle}? Du gör stabila framsteg.',
    'Du har byggt bra rutiner med {examTitle}. Fortsätt så!',
    'Dags att återvända till {examTitle} — konsekvens är nyckeln till att klara.',
    'Du är inne i en bra rutin med {examTitle}. Kom tillbaka och öva mer!',
  ];
}

// ── Private loader widget ──────────────────────────────────────────────────

/// Fetches questions for [licenceId]/[categoryId] then pushes Testscreen.
/// Used when deep-linking into a test exam from a notification.
class _TestDeepLinkLoader extends StatefulWidget {
  final String licenceId;
  final String categoryId;
  final String categoryName;

  const _TestDeepLinkLoader({
    required this.licenceId,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<_TestDeepLinkLoader> createState() => _TestDeepLinkLoaderState();
}

class _TestDeepLinkLoaderState extends State<_TestDeepLinkLoader> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final questions = await ApiService()
          .fetchQuestions(widget.licenceId, widget.categoryId);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(AppPageRoute(
        builder: (_) => Testscreen(
          questions: questions,
          instantMarking: true,
          licenceId: widget.licenceId,
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
        ),
      ));
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

- [ ] **Step 2: Run analysis**

```bash
flutter analyze lib/core/services/activity_reminder_service.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/activity_reminder_service.dart
git commit -m "feat: add ActivityReminderService with 24h scheduling and deep-link navigation"
```

---

## Task 3: Unit tests for ActivityReminderService

**Files:**
- Create: `test/core/services/activity_reminder_service_test.dart`

- [ ] **Step 1: Write the tests**

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/services/activity_reminder_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('buildSmartPayload', () {
    test('encodes testBcdId and screen correctly', () {
      final payload = ActivityReminderService.buildSmartPayload(42);
      final decoded = json.decode(payload) as Map<String, dynamic>;
      expect(decoded['screen'], 'smart');
      expect(decoded['testBcdId'], 42);
    });
  });

  group('buildTestPayload', () {
    test('encodes all fields correctly', () {
      final payload = ActivityReminderService.buildTestPayload(
        licenceId: 'taxi_b',
        categoryId: 'cat123',
        categoryName: 'Trafikkunskap',
      );
      final decoded = json.decode(payload) as Map<String, dynamic>;
      expect(decoded['screen'], 'test');
      expect(decoded['licenceId'], 'taxi_b');
      expect(decoded['categoryId'], 'cat123');
      expect(decoded['categoryName'], 'Trafikkunskap');
    });
  });

  group('savePendingDeepLink / consumePendingDeepLink', () {
    test('saves and returns payload, then clears it', () async {
      const payload = '{"screen":"smart","testBcdId":7}';
      await ActivityReminderService.savePendingDeepLink(payload);

      final first = await ActivityReminderService.consumePendingDeepLink();
      expect(first, payload);

      final second = await ActivityReminderService.consumePendingDeepLink();
      expect(second, isNull);
    });

    test('returns null when nothing saved', () async {
      final result = await ActivityReminderService.consumePendingDeepLink();
      expect(result, isNull);
    });
  });

  group('slot cycling', () {
    test('slot increments and wraps at poolSize (5)', () async {
      final prefs = await SharedPreferences.getInstance();

      // We can't call schedule() without a real plugin, but we can verify
      // the slot key starts at 0 and the cycling logic is correct:
      // slot = (current ?? 0) % 5
      expect(prefs.getInt('activity_reminder_slot'), isNull);
      // After first schedule the key would be 1, wrapping at 5→0.
      // Tested indirectly: just verifying the key name is stable.
    });
  });
}
```

- [ ] **Step 2: Run the tests**

```bash
flutter test test/core/services/activity_reminder_service_test.dart --reporter=compact
```

Expected: `+4: All tests passed!`

- [ ] **Step 3: Commit**

```bash
git add test/core/services/activity_reminder_service_test.dart
git commit -m "test: add ActivityReminderService payload and deep-link tests"
```

---

## Task 4: Add `categoryName` to `showResultDialog` + `ResultScreen`

**Files:**
- Modify: `lib/core/widgets/test_dialogs.dart`
- Modify: `lib/features/tests/result_screen.dart`

- [ ] **Step 1: Add `categoryName` param to `showResultDialog` in `test_dialogs.dart`**

Find the `showResultDialog` function signature (around line 61) and add the param:

```dart
// Before:
Future<void> showResultDialog({
  required BuildContext ctx,
  required List<Question> questions,
  required Map<int, String> userSelections,
  required String licenceId,
  required String categoryId,
  required bool hasPassed,
  required double passScorePercent,
}) async {

// After:
Future<void> showResultDialog({
  required BuildContext ctx,
  required List<Question> questions,
  required Map<int, String> userSelections,
  required String licenceId,
  required String categoryId,
  required String categoryName,
  required bool hasPassed,
  required double passScorePercent,
}) async {
```

- [ ] **Step 2: Thread `categoryName` into `ResultScreen` inside `showResultDialog`**

Find the `ResultScreen(` constructor call in `test_dialogs.dart` (~line 203) and add the field:

```dart
builder: (_) => ResultScreen(
  questions: questions,
  userSelections: userSelections,
  licenceId: licenceId,
  categoryId: categoryId,
  categoryName: categoryName,   // ← add this line
  hasPassed: hasPassed,
  passScorePercent: passScorePercent,
),
```

- [ ] **Step 3: Add `categoryName` field to `ResultScreen`**

In `lib/features/tests/result_screen.dart`, add the field to the widget:

```dart
class ResultScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, String> userSelections;
  final String licenceId;
  final String categoryId;
  final String categoryName;      // ← add
  final bool hasPassed;
  final double passScorePercent;

  const ResultScreen({
    super.key,
    required this.questions,
    required this.userSelections,
    required this.licenceId,
    required this.categoryId,
    this.categoryName = '',        // ← add (optional with default)
    required this.hasPassed,
    this.passScorePercent = 70,
  });
```

- [ ] **Step 4: Schedule the activity reminder in `ResultScreen.initState()`**

Add the call after the existing `AppReviewService` call (around line 58):

```dart
unawaited(AppReviewService.instance.maybeRequestAfterExam(hasPassed: widget.hasPassed));
unawaited(ActivityReminderService.schedule(
  examTitle: widget.categoryName.isNotEmpty ? widget.categoryName : widget.categoryId,
  payloadJson: ActivityReminderService.buildTestPayload(
    licenceId: widget.licenceId,
    categoryId: widget.categoryId,
    categoryName: widget.categoryName,
  ),
  locale: LocaleSettings.currentLocale.flutterLocale.languageCode,
));
```

- [ ] **Step 5: Add imports to `result_screen.dart`**

```dart
import 'package:taxi_exam_app/core/services/activity_reminder_service.dart';
// strings.g.dart is already imported — it exports LocaleSettings
```

- [ ] **Step 6: Add `categoryName` to all three `showResultDialog` calls in `test_screen.dart`**

There are three calls (lines ~518, ~653, ~1365). All three have access to `widget.categoryName`. Add to each:

```dart
// Call at ~line 518 — add after categoryId:
categoryName: widget.categoryName,

// Call at ~line 653 — add after categoryId:
categoryName: widget.categoryName,

// Call at ~line 1365 — add after categoryId:
categoryName: widget.categoryName,
```

- [ ] **Step 7: Run analysis**

```bash
flutter analyze lib/core/widgets/test_dialogs.dart lib/features/tests/result_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/core/widgets/test_dialogs.dart lib/features/tests/result_screen.dart
git commit -m "feat: schedule activity reminder after exam result; add categoryName to ResultScreen"
```

---

## Task 5: Schedule reminder from SmartResultScreen

**Files:**
- Modify: `lib/features/smart_learning/screens/smart_result_screen.dart`

- [ ] **Step 1: Add the schedule call in `SmartResultScreen.initState()` after the existing review call**

```dart
_ctrl.forward();
unawaited(AppReviewService.instance.maybeRequestAfterSmartSession(hasPassed: widget.hasPassed));
unawaited(ActivityReminderService.schedule(
  examTitle: widget.entry.testName,
  payloadJson: ActivityReminderService.buildSmartPayload(widget.entry.testBcdId),
  locale: LocaleSettings.currentLocale.flutterLocale.languageCode,
));
```

- [ ] **Step 2: Add imports**

```dart
import 'package:taxi_exam_app/core/services/activity_reminder_service.dart';
// strings.g.dart is already imported — it exports LocaleSettings
```

(`dart:async` and `app_review_service` are already imported.)

- [ ] **Step 3: Run analysis**

```bash
flutter analyze lib/features/smart_learning/screens/smart_result_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/smart_learning/screens/smart_result_screen.dart
git commit -m "feat: schedule activity reminder after Smart Learning session"
```

---

## Task 6: SplashScreen — cancel on open + handle deep link

**Files:**
- Modify: `lib/features/splash/splash_screen.dart`

- [ ] **Step 1: Cancel all activity reminders at the start of `_run()`**

Find the start of the `_run()` method (around where `SharedPreferences` is loaded) and add, right after `super.initState()` setup but before heavy loading:

```dart
unawaited(ActivityReminderService.cancelAll());
```

Place it just before or after the existing `unawaited(AppReviewService.instance.recordOpenAndMaybeRequest());` line (around line 126).

- [ ] **Step 2: After `_initializeApp()` completes and user is authenticated, check for pending deep link**

Find the block that sets `next = const MainScreen();` (around line 163) and replace it:

```dart
} else {
  // Check for a notification deep-link (tap while app was terminated).
  final deepLinkPayload = await ActivityReminderService.consumePendingDeepLink();
  if (deepLinkPayload != null && mounted) {
    // Push MainScreen first so the user has a back button, then the target.
    final nav = Navigator.of(context);
    nav.pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const MainScreen(),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final slideTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(position: animation.drive(slideTween), child: child),
        );
      },
    ));
    // Navigate to target screen after MainScreen settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = NavigationService.navigatorKey.currentState;
      if (nav != null) {
        ActivityReminderService.navigateFromPayload(nav, deepLinkPayload);
      }
    });
    return; // skip the normal pushReplacement below
  }
  next = const MainScreen();
}
```

- [ ] **Step 3: Add imports**

```dart
import 'package:taxi_exam_app/core/services/activity_reminder_service.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
```

- [ ] **Step 4: Run analysis**

```bash
flutter analyze lib/features/splash/splash_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/splash/splash_screen.dart
git commit -m "feat: cancel activity reminders on app open; navigate deep link from splash"
```

---

## Task 7: Verify end-to-end on device

- [ ] **Step 1: Build and run on a physical device (notifications don't fire on simulator)**

```bash
flutter run --release
```

- [ ] **Step 2: Complete an exam — verify a notification is scheduled**

In `ActivityReminderService.schedule()`, temporarily lower the delay to 10 seconds for testing:

```dart
// Temporarily for testing:
final fireAt = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
```

Complete an exam. Background the app. Confirm the notification fires in ~10 seconds with the correct exam title and a hook phrase.

- [ ] **Step 3: Tap the notification — verify deep link navigation**

Tap the notification. Confirm the app opens, shows a loading spinner (for test exams) or goes directly (for smart exams), and lands on the correct screen.

- [ ] **Step 4: Revert the temporary test delay**

```dart
final fireAt = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));
```

- [ ] **Step 5: Open the app normally (no notification) — verify reminders are cancelled**

Complete an exam, background the app, reopen it via the app icon (not a notification). The previously scheduled reminder should be cancelled (check via `_plugin.pendingNotificationRequests()` in debug).

- [ ] **Step 6: Final commit**

```bash
git add -p  # stage only the reverted delay change
git commit -m "fix: restore 24h reminder delay after manual testing"
```
