import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/services/streak_notification_service.dart';

class StreakSettingsProvider extends ChangeNotifier {
  static const _keyDeadline = 'exam_deadline';
  static const _keyWeekdays = 'practice_weekdays';
  static const _keyDaysCount = 'practice_days_per_week';

  DateTime? _examDeadline;
  Set<int> _practiceWeekdays = {0, 1, 2, 3, 4}; // Mon–Fri

  DateTime? get examDeadline => _examDeadline;
  Set<int> get practiceWeekdays => Set.unmodifiable(_practiceWeekdays);
  int get weeklyGoal => _practiceWeekdays.length;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawDeadline = prefs.getString(_keyDeadline);
      if (rawDeadline != null) {
        _examDeadline = DateTime.tryParse(rawDeadline);
      }
      final rawWeekdays = prefs.getString(_keyWeekdays);
      if (rawWeekdays != null && rawWeekdays.isNotEmpty) {
        final parsed = rawWeekdays
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .where((d) => d >= 0 && d <= 6)
            .toSet();
        if (parsed.isNotEmpty) _practiceWeekdays = parsed;
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> update({
    required DateTime? examDeadline,
    required Set<int> practiceWeekdays,
  }) async {
    _examDeadline = examDeadline;
    _practiceWeekdays = practiceWeekdays.isEmpty ? {0} : practiceWeekdays;
    await _persist();
    StreakNotificationService.scheduleStreakReminders(_practiceWeekdays)
        .ignore();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_examDeadline != null) {
        await prefs.setString(_keyDeadline, _examDeadline!.toIso8601String());
      } else {
        await prefs.remove(_keyDeadline);
      }
      await prefs.setString(_keyWeekdays, _practiceWeekdays.join(','));
      await prefs.setInt(_keyDaysCount, _practiceWeekdays.length);
    } catch (_) {}
  }
}
