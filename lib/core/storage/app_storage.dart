import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/features/smart_learning/models/smart_progress.dart';
import 'package:taxi_exam_app/features/smart_learning/models/weak_question.dart';
import 'package:taxi_exam_app/core/services/home_data_cache.dart';
import 'package:taxi_exam_app/core/services/saved_questions_service.dart';
import 'package:taxi_exam_app/features/dashboard/models/subscribed_exam.dart';

/// Single source of truth for ALL local storage in the app.
///
/// ## Per-user Hive isolation
/// Each user gets their own Hive boxes, suffixed with their backend user ID
/// (e.g. `testAttempts_42`). Call [setCurrentUser] immediately after tokens
/// are set so every subsequent box accessor uses the right suffix.
/// Call [clearCurrentUser] on logout.
///
/// ## Session isolation
/// Call [clearUserData] on every session end (explicit logout OR 401 redirect).
/// Hive boxes are NOT cleared — per-user naming provides isolation and data
/// persists for the same user across logins. Only SharedPreferences keys and
/// in-memory caches are wiped.
class AppStorage {
  AppStorage._();

  // ── Current user scope ──────────────────────────────────────────────────────

  static String _userId = '';

  /// Set immediately after tokens are written (call from [DioClient.setTokens]
  /// and [DioClient.init]). Scopes all Hive box accessors to this user.
  static void setCurrentUser(String userId) => _userId = userId;

  /// Reset on logout so box name getters return the unsuffixed fallback name.
  static void clearCurrentUser() => _userId = '';

  /// The currently logged-in user's ID, or empty string if not set.
  static String get currentUserId => _userId;

  static String get _suffix => _userId.isNotEmpty ? '_$_userId' : '';

  // ── Hive box base names (constants) ────────────────────────────────────────

  static const String kTestAttempts = 'testAttempts';
  static const String kSubscribedExams = 'subscribed_exams';
  static const String kNotifications = 'notifications';
  static const String kReceipts = 'purchase_receipts';
  static const String kSmartProgress = 'chunkProgress';
  static const String kWeakQuestions = 'weakQuestions';

  // ── Hive box runtime names (user-scoped) ───────────────────────────────────

  static String get testAttemptsBoxName => '$kTestAttempts$_suffix';
  static String get subscribedExamsBoxName => '$kSubscribedExams$_suffix';
  static String get notificationsBoxName => '$kNotifications$_suffix';
  static String get receiptsBoxName => '$kReceipts$_suffix';

  // ── SharedPreferences keys (user-specific) ──────────────────────────────────

  /// Cached serialised user JSON written after login.
  static const String kUserJson = 'user';

  /// Returns whether the current user is allowed to take screenshots.
  /// Reads synchronously from the cached user JSON. Defaults to false
  /// (screenshots blocked) when no stored value is found.
  static bool allowScreenshots() {
    try {
      // SharedPreferences.getInstance() is async, but we use the in-memory
      // cache via the synchronous maybeGet alternative. We keep it simple:
      // the value is always present after the first /self response.
      // Read from the last-written in-memory value — updated by api_service
      // on every /self call. Can't await here so no async prefs access.
      return _cachedAllowScreenshots;
    } catch (_) {
      return false;
    }
  }

  // Updated by ApiService after every successful /self response.
  static bool _cachedAllowScreenshots = false;
  static final ValueNotifier<bool> allowScreenshotsNotifier =
      ValueNotifier(false);
  static void updateAllowScreenshots(bool value) {
    _cachedAllowScreenshots = value;
    allowScreenshotsNotifier.value = value;
  }

  /// App display language — `'en'` or `'sv'`.
  static const String kLanguage = 'language';

  /// Prefix for saved-question bookmark keys — e.g. `saved_question_ids_bcd:5`.
  static const String kSavedQuestionsPrefix = 'saved_question_ids_';

  /// SharedPreferences key for a deferred IAP receipt that failed backend
  /// verification. Cleared on every logout so a subsequent user cannot
  /// accidentally claim a previous user's Apple purchase.
  static const String kIapDeferredReceipt = 'iap_deferred_receipt';

  /// Persisted guest refresh token — survives explicit logout so the same guest
  /// account can be restored on the same device without creating a new one.
  /// Stored in SharedPreferences (not secure storage) so it is NOT wiped by
  /// [DioClient.logout]'s secureStorage.deleteAll(). Cleared only when the
  /// guest converts to a real account via [ApiService.convertGuest].
  static const String kGuestRefreshToken = 'guest_refresh_token';

  // ── Typed box accessors ─────────────────────────────────────────────────────

  /// Returns the current user's testAttempts box, opening it if necessary.
  static Future<Box<TestAttempt>> testAttemptsBox() =>
      _openBox<TestAttempt>(testAttemptsBoxName);

  /// Returns the current user's subscribed_exams box, opening it if necessary.
  static Future<Box<SubscribedExam>> subscribedExamsBox() =>
      _openBox<SubscribedExam>(subscribedExamsBoxName);

  /// Returns the current user's notifications box, opening it if necessary.
  static Future<Box<LocalNotification>> notificationsBox() =>
      _openBox<LocalNotification>(notificationsBoxName);

  /// Returns the current user's purchase receipts box, opening it if necessary.
  static Future<Box<String>> receiptsBox() => _openBox<String>(receiptsBoxName);

  /// Chunk learning progress — not user-scoped (persists across logins on same device).
  static Future<Box<SmartProgress>> smartProgressBox() =>
      _openBox<SmartProgress>(kSmartProgress);

  /// Weak question pool — not user-scoped (same reasoning as chunk progress).
  static Future<Box<WeakQuestion>> weakQuestionsBox() =>
      _openBox<WeakQuestion>(kWeakQuestions);

  // ── User-data wipe ──────────────────────────────────────────────────────────

  /// Clears user-specific state on logout.
  ///
  /// Per-user Hive box naming provides isolation for normal logins. As a safety
  /// net, testAttempts and subscribedExams boxes are also cleared when [_userId]
  /// is empty — that means JWT parsing failed and all users share the unsuffixed
  /// box name, so we must wipe it to prevent cross-user leakage.
  ///
  /// Covers:
  ///   1. Notifications Hive box (ephemeral — no need to persist across sessions)
  ///   2. Safety net: testAttempts + subscribedExams if user ID was not resolved
  ///   3. SharedPreferences: user JSON, IAP deferred receipt, bookmarks
  ///   4. In-memory service caches: [BcdCache], [SavedQuestionsService]
  ///   5. Resets [_userId] so the next session starts clean
  ///
  /// Does NOT touch app-wide preferences (language, theme, font, onboarding).
  static Future<void> clearUserData() async {
    // 1. Notifications box (ephemeral — cleared per session)
    await _clearNotificationsBox();

    // 2. Safety net: if JWT parsing failed (_userId is empty), all users share
    // the same unsuffixed box — clear it to prevent cross-user data leakage.
    if (_userId.isEmpty) {
      await Future.wait([
        _clearTestAttemptsBox(),
        _clearSubscribedExamsBox(),
        _clearSmartProgressBox(),
        _clearWeakQuestionsBox(),
      ]);
    }

    // 3. SharedPreferences — user-specific keys only
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kUserJson);
      await prefs.remove(kIapDeferredReceipt);
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

    // 4. In-memory service caches
    _invalidateBcdCacheIfAvailable();
    SavedQuestionsService.clearMemoryCache();
    HomeDataCache.invalidate();
    updateAllowScreenshots(false);

    // 5. Reset user scope
    clearCurrentUser();
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  static Future<Box<T>> _openBox<T>(String name) async =>
      Hive.isBoxOpen(name) ? Hive.box<T>(name) : await Hive.openBox<T>(name);

  static Future<void> _clearTestAttemptsBox() async {
    final name = testAttemptsBoxName;
    try {
      await (await _openBox<TestAttempt>(name)).clear();
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$name": $e');
    }
  }

  static Future<void> _clearSubscribedExamsBox() async {
    final name = subscribedExamsBoxName;
    try {
      await (await _openBox<SubscribedExam>(name)).clear();
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$name": $e');
    }
  }

  static Future<void> _clearNotificationsBox() async {
    final name = notificationsBoxName;
    try {
      await (await _openBox<LocalNotification>(name)).clear();
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$name": $e');
    }
  }

  static Future<void> _clearSmartProgressBox() async {
    try {
      await (await _openBox<SmartProgress>(kSmartProgress)).clear();
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$kSmartProgress": $e');
    }
  }

  static Future<void> _clearWeakQuestionsBox() async {
    try {
      await (await _openBox<WeakQuestion>(kWeakQuestions)).clear();
    } catch (e) {
      debugPrint('[AppStorage] failed to clear box "$kWeakQuestions": $e');
    }
  }

  static void _invalidateBcdCacheIfAvailable() {
    BcdCache.invalidateIfInitialized();
  }
}
