import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/saved_questions_service.dart';
import 'package:taxi_exam_app/features/dashboard/models/subscribed_exam.dart';

/// Single source of truth for ALL local storage in the app.
///
/// ## Box names
/// All Hive box name strings live here as constants — never write bare strings
/// elsewhere. Reference [kTestAttempts], [kSubscribedExams], [kNotifications].
///
/// ## Session isolation
/// Call [clearUserData] on every session end (explicit logout OR 401 redirect).
/// It clears every piece of user-specific state in one shot:
///   • Hive boxes (test attempts, subscribed exams, notifications)
///   • SharedPreferences: saved-question bookmarks + cached user JSON
///   • In-memory service caches (BcdCache, SavedQuestionsService)
class AppStorage {
  AppStorage._();

  // ── Hive box names ──────────────────────────────────────────────────────────

  static const String kTestAttempts    = 'testAttempts';
  static const String kSubscribedExams = 'subscribed_exams';
  static const String kNotifications   = 'notifications';

  // ── SharedPreferences keys (user-specific) ──────────────────────────────────

  /// Cached serialised user JSON written after login.
  static const String kUserJson = 'user';

  /// Prefix for saved-question bookmark keys — e.g. `saved_question_ids_bcd:5`.
  static const String kSavedQuestionsPrefix = 'saved_question_ids_';

  // ── Typed box accessors ─────────────────────────────────────────────────────

  /// Returns the testAttempts box, opening it if necessary.
  static Future<Box<TestAttempt>> testAttemptsBox() async =>
      Hive.isBoxOpen(kTestAttempts)
          ? Hive.box<TestAttempt>(kTestAttempts)
          : await Hive.openBox<TestAttempt>(kTestAttempts);

  /// Returns the subscribed_exams box, opening it if necessary.
  static Future<Box<SubscribedExam>> subscribedExamsBox() async =>
      Hive.isBoxOpen(kSubscribedExams)
          ? Hive.box<SubscribedExam>(kSubscribedExams)
          : await Hive.openBox<SubscribedExam>(kSubscribedExams);

  /// Returns the notifications box (must already be open — opened during app init).
  static Box<LocalNotification> notificationsBox() =>
      Hive.box<LocalNotification>(kNotifications);

  // ── User-data wipe ──────────────────────────────────────────────────────────

  /// Clears every user-specific storage layer.
  ///
  /// Covers:
  ///   1. Hive boxes: test attempts, subscribed exams, notifications
  ///   2. SharedPreferences: saved-question bookmarks + user JSON
  ///   3. In-memory caches: [BcdCache], [SavedQuestionsService]
  ///
  /// Does NOT touch app-wide preferences (language, theme, font, onboarding).
  static Future<void> clearUserData() async {
    // 1. Hive boxes
    await _clearBox(kTestAttempts);
    await _clearBox(kSubscribedExams);
    await _clearBox(kNotifications);

    // 2. SharedPreferences — user-specific keys only
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kUserJson);
      final staleKeys = prefs
          .getKeys()
          .where((k) => k.startsWith(kSavedQuestionsPrefix))
          .toList();
      for (final key in staleKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('[AppStorage] SharedPreferences clear failed: $e');
    }

    // 3. In-memory service caches
    BcdCache.instance.invalidate();
    SavedQuestionsService.clearMemoryCache();
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  static Future<void> _clearBox(String name) async {
    try {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      } else {
        final box = await Hive.openBox(name);
        await box.clear();
        await box.close();
      }
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$name": $e');
    }
  }
}
