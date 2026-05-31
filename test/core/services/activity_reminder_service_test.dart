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
}
