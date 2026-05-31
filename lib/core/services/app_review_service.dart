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
  static const _keyFirstSmartShown = 'review_first_smart_shown';
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

  /// Called from ResultScreen after the first ever passed exam.
  Future<void> maybeRequestAfterExam({required bool hasPassed}) async {
    if (!hasPassed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyFirstExamShown) ?? false) return;
      await _request();
      await prefs.setBool(_keyFirstExamShown, true);
    } catch (_) {}
  }

  /// Called from SmartResultScreen after the first ever passed Smart Learning session.
  Future<void> maybeRequestAfterSmartSession({required bool hasPassed}) async {
    if (!hasPassed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyFirstSmartShown) ?? false) return;
      await _request();
      await prefs.setBool(_keyFirstSmartShown, true);
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
