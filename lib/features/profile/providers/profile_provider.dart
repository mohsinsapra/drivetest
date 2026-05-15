import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';

class ProfileProvider extends ChangeNotifier {
  static final ProfileProvider _instance = ProfileProvider._();
  factory ProfileProvider() => _instance;
  ProfileProvider._();

  final _api = ApiService();

  // ── User data ─────────────────────────────────────────────────────────────

  String? username;
  String? email;
  bool hasPassword = true;
  bool isGoogleAccount = false;
  bool isDemo = false;
  bool isGuest = false;

  // ── Loading states ────────────────────────────────────────────────────────

  bool profileLoading = true;
  bool savingProfile = false;
  bool settingPassword = false;
  bool deletingAccount = false;

  // ── Local prefs (fast read for profile display) ───────────────────────────

  Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user');
    if (stored != null) {
      final map = jsonDecode(stored) as Map<String, dynamic>;
      username = map['username']?.toString() ?? 'Unknown';
      email = map['email']?.toString() ?? '';
      isGuest = map['is_guest'] == true;
      notifyListeners();
    }
  }

  // ── API: load full profile ────────────────────────────────────────────────

  Future<void> loadProfile() async {
    profileLoading = true;
    notifyListeners();

    try {
      final user = await _api.fetchCurrentUser();
      final map = Map<String, dynamic>.from(user as Map);
      username = (map['username'] ?? '').toString();
      email = (map['email'] ?? '').toString();
      hasPassword =
          (map['has_password'] ?? map['has_usable_password']) == true;
      isGoogleAccount = map['is_google_account'] == true;
      isDemo = map['is_demo'] == true;
      isGuest = map['is_guest'] == true;

      // Persist so the correct menu state is shown immediately on next cold start.
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('user');
      final existing = stored != null
          ? Map<String, dynamic>.from(jsonDecode(stored) as Map)
          : <String, dynamic>{};
      existing['is_guest'] = isGuest;
      await prefs.setString('user', jsonEncode(existing));
    } catch (_) {
      rethrow;
    } finally {
      profileLoading = false;
      notifyListeners();
    }
  }

  // ── API: save profile ─────────────────────────────────────────────────────

  Future<void> saveProfile({
    required String username,
    required String email,
  }) async {
    savingProfile = true;
    notifyListeners();

    try {
      final updated = await _api.updateProfile(
        username: username,
        email: email,
      );
      this.username = username;
      this.email = email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updated));
    } finally {
      savingProfile = false;
      notifyListeners();
    }
  }

  // ── API: set password ─────────────────────────────────────────────────────

  Future<void> setPassword(String newPassword) async {
    settingPassword = true;
    notifyListeners();

    try {
      await _api.setPassword(newPassword: newPassword);
      hasPassword = true;
    } finally {
      settingPassword = false;
      notifyListeners();
    }
  }

  // ── API: submit feedback ──────────────────────────────────────────────────

  Future<bool> submitFeedback({
    required String message,
    required String subject,
    required String feedbackType,
  }) {
    return _api.submitAppFeedback(
      message: message,
      subject: subject,
      screenContext: 'profile',
      feedbackType: feedbackType,
      contactEmail: email ?? '',
    );
  }

  // ── API: logout ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    _navigateToAuth();
  }

  // ── API: delete account ───────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    deletingAccount = true;
    notifyListeners();

    try {
      await _api.deleteAccount();
      try {
        await _api.logout();
      } catch (_) {}

      // Preserve app-level prefs (language, theme, onboarding) while clearing user data
      try {
        final prefs = await SharedPreferences.getInstance();
        final lang = prefs.getString('language');
        final isDark = prefs.getBool('dark_mode');
        final onboardingDone = prefs.getBool('onboarding_complete');
        await prefs.clear();
        if (lang != null) await prefs.setString('language', lang);
        if (isDark != null) await prefs.setBool('dark_mode', isDark);
        if (onboardingDone != null) {
          await prefs.setBool('onboarding_complete', onboardingDone);
        }
      } catch (_) {}

      try {
        final attemptsBox = await Hive.openBox<TestAttempt>('testAttempts');
        await attemptsBox.clear();
        await Hive.close();
        await Hive.deleteFromDisk();
      } catch (_) {}

      _navigateToAuth();
    } finally {
      deletingAccount = false;
      notifyListeners();
    }
  }

  // ── Error formatting ──────────────────────────────────────────────────────

  String extractApiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        for (final key in ['username', 'email']) {
          final errors = map[key];
          if (errors is List && errors.isNotEmpty) {
            final msg = errors.first.toString();
            if (msg.toLowerCase().contains('already exists')) {
              return key == 'username'
                  ? 'This username is already taken.'
                  : 'This email is already in use.';
            }
            return msg;
          }
        }
        final detail = map['detail'];
        if (detail != null && detail.toString().trim().isNotEmpty) {
          return detail.toString();
        }
      }
      if (data is String && data.trim().isNotEmpty) return data;
    }
    return 'Request failed. Please try again.';
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _navigateToAuth() {
    final nav = NavigationService.navigatorKey.currentState;
    nav?.pushAndRemoveUntil(
      AppPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }
}
