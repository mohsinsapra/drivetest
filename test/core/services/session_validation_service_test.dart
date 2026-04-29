import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/services/session_validation_service.dart';

void main() {
  group('SessionValidationService', () {
    test('validates on resume when authenticated and interval elapsed', () async {
      var now = DateTime(2026, 4, 29, 12, 0, 0);
      var calls = 0;
      final service = SessionValidationService(
        isAuthenticated: () => true,
        fetchCurrentUser: () async {
          calls += 1;
        },
        now: () => now,
        minInterval: const Duration(minutes: 3),
      );

      await service.onAppResumed();
      expect(calls, 1);

      now = now.add(const Duration(minutes: 2));
      await service.onAppResumed();
      expect(calls, 1);

      now = now.add(const Duration(minutes: 2));
      await service.onAppResumed();
      expect(calls, 2);
    });

    test('skips validation when logged out', () async {
      var calls = 0;
      final service = SessionValidationService(
        isAuthenticated: () => false,
        fetchCurrentUser: () async {
          calls += 1;
        },
      );

      await service.onAppResumed();
      expect(calls, 0);
    });

    test('does not start a second validation while one is running', () async {
      final completer = Completer<void>();
      var calls = 0;
      final service = SessionValidationService(
        isAuthenticated: () => true,
        fetchCurrentUser: () {
          calls += 1;
          return completer.future;
        },
      );

      final first = service.onAppResumed();
      await Future<void>.delayed(Duration.zero);
      final second = service.onAppResumed();

      expect(calls, 1);

      completer.complete();
      await Future.wait([first, second]);
    });

    test('polls periodically while attached', () async {
      var calls = 0;
      final service = SessionValidationService(
        isAuthenticated: () => true,
        fetchCurrentUser: () async {
          calls += 1;
        },
        minInterval: const Duration(milliseconds: 10),
      );

      service.startForegroundPolling();
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(calls, 1);

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(calls, greaterThanOrEqualTo(2));

      service.dispose();
    });
  });
}
