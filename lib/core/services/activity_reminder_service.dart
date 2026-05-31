import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
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

    final fireAt = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

    await StreakNotificationService.plugin.zonedSchedule(
      notifId,
      examTitle,
      body,
      fireAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders to continue your exam practice',
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
        final testBcdId = (data['testBcdId'] as num?)?.toInt();
        if (testBcdId == null) return;
        final entry = _entryForTestBcdId(testBcdId);
        if (entry == null) return;
        nav.push(AppPageRoute(
          builder: (_) => SmartExamScreen(entry: entry),
        ));
      } else if (screen == 'test') {
        final licenceId = (data['licenceId'] as String?) ?? '';
        final categoryId = (data['categoryId'] as String?) ?? '';
        if (licenceId.isEmpty || categoryId.isEmpty) return;
        final categoryName = (data['categoryName'] as String?) ?? '';
        nav.push(AppPageRoute(
          builder: (_) => _TestDeepLinkLoader(
            licenceId: licenceId,
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ));
      }
    } catch (e) {
      debugPrint('[ActivityReminder] navigateFromPayload error: $e');
    }
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
            return _entryFromTest(test, sub['name']?.toString() ?? '', subId);
          }
        }
      }
    }
    return null;
  }

  static SmartExamEntry _entryFromTest(
      Map<String, dynamic> test, String catName, int catId) {
    final qc = test['question_count'] as int? ?? 0;
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
