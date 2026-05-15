import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/features/streak/streak_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreakSettingsProvider', () {
    test('defaults to Mon–Fri and no deadline', () {
      final provider = StreakSettingsProvider();
      expect(provider.practiceWeekdays, equals({0, 1, 2, 3, 4}));
      expect(provider.examDeadline, isNull);
      expect(provider.weeklyGoal, equals(5));
    });

    test('load reads exam_deadline from SharedPreferences', () async {
      final deadline = DateTime(2026, 9, 15);
      SharedPreferences.setMockInitialValues({
        'exam_deadline': deadline.toIso8601String(),
        'practice_weekdays': '0,1,2',
      });
      final provider = StreakSettingsProvider();
      await provider.load();
      expect(provider.examDeadline?.year, 2026);
      expect(provider.examDeadline?.month, 9);
      expect(provider.examDeadline?.day, 15);
    });

    test('load reads practice_weekdays from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'practice_weekdays': '1,3,5',
      });
      final provider = StreakSettingsProvider();
      await provider.load();
      expect(provider.practiceWeekdays, equals({1, 3, 5}));
      expect(provider.weeklyGoal, equals(3));
    });

    test('load ignores out-of-range weekday values', () async {
      SharedPreferences.setMockInitialValues({
        'practice_weekdays': '0,7,99,3',
      });
      final provider = StreakSettingsProvider();
      await provider.load();
      expect(provider.practiceWeekdays, equals({0, 3}));
    });

    test('load falls back to default weekdays when key missing', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = StreakSettingsProvider();
      await provider.load();
      expect(provider.practiceWeekdays, equals({0, 1, 2, 3, 4}));
    });

    test('update persists exam_deadline to SharedPreferences', () async {
      final provider = StreakSettingsProvider();
      final deadline = DateTime(2027, 3, 20);
      await provider
          .update(examDeadline: deadline, practiceWeekdays: {0, 2, 4});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('exam_deadline'), deadline.toIso8601String());
    });

    test('update persists practice_weekdays to SharedPreferences', () async {
      final provider = StreakSettingsProvider();
      await provider.update(examDeadline: null, practiceWeekdays: {0, 2, 4});
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('practice_weekdays')!;
      final parsed = stored.split(',').map(int.parse).toSet();
      expect(parsed, equals({0, 2, 4}));
    });

    test('update persists practice_days_per_week count', () async {
      final provider = StreakSettingsProvider();
      await provider.update(examDeadline: null, practiceWeekdays: {0, 1, 2});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('practice_days_per_week'), equals(3));
    });

    test('update with empty weekdays defaults to {0}', () async {
      final provider = StreakSettingsProvider();
      await provider.update(examDeadline: null, practiceWeekdays: {});
      expect(provider.practiceWeekdays, equals({0}));
    });

    test('update notifies listeners', () async {
      final provider = StreakSettingsProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.update(examDeadline: null, practiceWeekdays: {1, 2});
      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('weeklyGoal reflects practiceWeekdays length', () async {
      final provider = StreakSettingsProvider();
      await provider
          .update(examDeadline: null, practiceWeekdays: {0, 1, 2, 3, 4, 5, 6});
      expect(provider.weeklyGoal, equals(7));
    });
  });
}
