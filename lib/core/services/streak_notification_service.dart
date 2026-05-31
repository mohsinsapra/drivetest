import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/services/activity_reminder_service.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class StreakNotificationService {
  static const _channelId = 'streak_reminders';
  static const _channelName = 'Streak Reminders';

  // Morning window: 08:00–10:00, evening window: 19:00–21:00
  static const _morningStartHour = 8;
  static const _morningEndHour = 10;
  static const _eveningStartHour = 19;
  static const _eveningEndHour = 21;

  // IDs 100–106: morning (Mon=100…Sun=106)
  // IDs 107–113: evening (Mon=107…Sun=113)
  static const _morningIdOffset = 100;
  static const _eveningIdOffset = 107;

  static const _keyMorningHour = 'notif_morning_hour';
  static const _keyMorningMinute = 'notif_morning_minute';
  static const _keyEveningHour = 'notif_evening_hour';
  static const _keyEveningMinute = 'notif_evening_minute';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Exposed so ActivityReminderService can schedule without a second init().
  static FlutterLocalNotificationsPlugin get plugin => _plugin;
  static bool _initialised = false;
  static final _rng = Random();

  static Future<void> init() async {
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Cold-start: app was terminated when user tapped notification
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final resp = launchDetails!.notificationResponse;
      final id = resp?.id ?? -1;
      if (resp?.payload != null && id >= 200 && id < 205) {
        await ActivityReminderService.savePendingDeepLink(resp!.payload!);
      }
    }

    _initialised = true;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb || !_initialised) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  /// Schedules a morning and evening reminder on each selected practice day.
  /// Random times within the morning/evening windows are generated once and
  /// stored so they remain stable across app restarts.
  static Future<void> scheduleStreakReminders(Set<int> weekdays) async {
    if (kIsWeb || !_initialised) return;

    final times = await _loadOrGenerateTimes();
    final mH = times.$1, mMin = times.$2, eH = times.$3, eMin = times.$4;

    // Cancel all existing streak notifications (14 slots).
    for (int i = 0; i < 14; i++) {
      await _plugin.cancel(_morningIdOffset + i);
    }

    for (final weekday in weekdays) {
      await _scheduleWeekly(
        id: _morningIdOffset + weekday,
        title: '☀️ Morning study reminder',
        body: "Start your practice session — build that streak!",
        weekday: weekday,
        hour: mH,
        minute: mMin,
      );
      await _scheduleWeekly(
        id: _eveningIdOffset + weekday,
        title: '🌙 Evening streak check-in',
        body: "Don't let today slip by — keep your streak alive!",
        weekday: weekday,
        hour: eH,
        minute: eMin,
      );
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialised) return;
    for (int i = 0; i < 14; i++) {
      await _plugin.cancel(_morningIdOffset + i);
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextOccurrence(weekday, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription:
              'Daily reminders on your practice days to keep your streak',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Loads stored times or generates fresh random ones and persists them.
  static Future<(int, int, int, int)> _loadOrGenerateTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final mH = prefs.getInt(_keyMorningHour);
    final mMin = prefs.getInt(_keyMorningMinute);
    final eH = prefs.getInt(_keyEveningHour);
    final eMin = prefs.getInt(_keyEveningMinute);

    if (mH != null && mMin != null && eH != null && eMin != null) {
      return (mH, mMin, eH, eMin);
    }

    final newMH = _randomHour(_morningStartHour, _morningEndHour);
    final newMMin = _randomMinute();
    final newEH = _randomHour(_eveningStartHour, _eveningEndHour);
    final newEMin = _randomMinute();

    await prefs.setInt(_keyMorningHour, newMH);
    await prefs.setInt(_keyMorningMinute, newMMin);
    await prefs.setInt(_keyEveningHour, newEH);
    await prefs.setInt(_keyEveningMinute, newEMin);

    return (newMH, newMMin, newEH, newEMin);
  }

  /// Forces a fresh random time pair on next save (call when user explicitly
  /// wants to reshuffle times).
  static Future<void> resetTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMorningHour);
    await prefs.remove(_keyMorningMinute);
    await prefs.remove(_keyEveningHour);
    await prefs.remove(_keyEveningMinute);
  }

  static int _randomHour(int start, int end) =>
      start + _rng.nextInt(end - start);

  static int _randomMinute() => _rng.nextInt(60);

  static tz.TZDateTime _nextOccurrence(int weekday, int hour, int minute) {
    final targetWeekday = weekday + 1; // DateTime: 1=Mon…7=Sun
    final now = tz.TZDateTime.now(tz.local);
    var candidate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (candidate.weekday != targetWeekday ||
        candidate.isBefore(now.add(const Duration(minutes: 1)))) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// Returns the stored notification times for display. Returns null if not yet generated.
  static Future<
      ({
        int morningHour,
        int morningMinute,
        int eveningHour,
        int eveningMinute
      })?> getScheduledTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final mH = prefs.getInt(_keyMorningHour);
    final mMin = prefs.getInt(_keyMorningMinute);
    final eH = prefs.getInt(_keyEveningHour);
    final eMin = prefs.getInt(_keyEveningMinute);
    if (mH == null || mMin == null || eH == null || eMin == null) return null;
    return (
      morningHour: mH,
      morningMinute: mMin,
      eveningHour: eH,
      eveningMinute: eMin
    );
  }

  // ─── Notification tap handlers ────────────────────────────────────────────

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
}
