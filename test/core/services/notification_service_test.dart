import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/services/notification_service.dart';

void main() {
  group('notificationPayloadFromRaw', () {
    test('prefers notification title and body when present', () {
      final payload = notificationPayloadFromRaw(
        title: 'System title',
        body: 'System body',
        data: const {
          'title': 'Data title',
          'body': 'Data body',
          'type': 'payment',
        },
      );

      expect(payload.title, 'System title');
      expect(payload.body, 'System body');
      expect(payload.type, 'payment');
      expect(payload.hasVisibleContent, isTrue);
    });

    test('falls back to data-only payload fields', () {
      final payload = notificationPayloadFromRaw(
        data: const {
          'title': 'Background title',
          'body': 'Background body',
          'type': 'subscription',
        },
      );

      expect(payload.title, 'Background title');
      expect(payload.body, 'Background body');
      expect(payload.type, 'subscription');
      expect(payload.hasVisibleContent, isTrue);
    });

    test('defaults type and reports empty content correctly', () {
      final payload = notificationPayloadFromRaw(
        data: const {'type': ''},
      );

      expect(payload.title, '');
      expect(payload.body, '');
      expect(payload.type, 'general');
      expect(payload.hasVisibleContent, isFalse);
    });
  });
}
