import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/home_data_cache.dart';
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

  static const String kTestAttempts = 'testAttempts';
  static const String kSubscribedExams = 'subscribed_exams';
  static const String kNotifications = 'notifications';
  static const String kReceipts = 'purchase_receipts';

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

  /// Returns the purchase receipts box (JSON strings keyed by receipt number).
  static Future<Box<String>> receiptsBox() async => Hive.isBoxOpen(kReceipts)
      ? Hive.box<String>(kReceipts)
      : await Hive.openBox<String>(kReceipts);

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
    await _clearTestAttemptsBox();
    await _clearSubscribedExamsBox();
    await _clearNotificationsBox();
    // Receipts are intentionally NOT cleared on logout so purchase history
    // remains accessible after re-login and for expired subscriptions.

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
    _invalidateBcdCacheIfAvailable();
    SavedQuestionsService.clearMemoryCache();
    HomeDataCache.invalidate();
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  static Future<void> _clearTestAttemptsBox() async {
    try {
      final box = Hive.isBoxOpen(kTestAttempts)
          ? Hive.box<TestAttempt>(kTestAttempts)
          : await Hive.openBox<TestAttempt>(kTestAttempts);
      await box.clear();
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$kTestAttempts": $e');
    }
  }

  static Future<void> _clearSubscribedExamsBox() async {
    try {
      final box = Hive.isBoxOpen(kSubscribedExams)
          ? Hive.box<SubscribedExam>(kSubscribedExams)
          : await Hive.openBox<SubscribedExam>(kSubscribedExams);
      await box.clear();
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$kSubscribedExams": $e');
    }
  }

  static Future<void> _clearNotificationsBox() async {
    try {
      final box = Hive.isBoxOpen(kNotifications)
          ? Hive.box<LocalNotification>(kNotifications)
          : await Hive.openBox<LocalNotification>(kNotifications);
      await box.clear();
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$kNotifications": $e');
    }
  }

  static void _invalidateBcdCacheIfAvailable() {
    BcdCache.invalidateIfInitialized();
  }
}
