import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';

void main() {
  group('NavigationFeedbackService', () {
    test('uses vibration for Android navigation changes', () async {
      final driver = _FakeNavigationFeedbackDriver(hasVibrator: true);
      var hapticCalls = 0;
      final service = NavigationFeedbackService(
        driver: driver,
        isWeb: false,
        platformResolver: () => TargetPlatform.android,
        selectionClick: () async {
          hapticCalls++;
        },
      );

      await service.play();

      expect(driver.hasVibratorCalls, 1);
      expect(driver.vibrateCalls, 1);
      expect(driver.lastDurationMs, 15);
      expect(hapticCalls, 0);
    });

    test('falls back to haptic selection click on native iOS', () async {
      final driver = _FakeNavigationFeedbackDriver(hasVibrator: true);
      var hapticCalls = 0;
      final service = NavigationFeedbackService(
        driver: driver,
        isWeb: false,
        platformResolver: () => TargetPlatform.iOS,
        selectionClick: () async {
          hapticCalls++;
        },
      );

      await service.play();

      expect(driver.hasVibratorCalls, 0);
      expect(driver.vibrateCalls, 0);
      expect(hapticCalls, 1);
    });

    test('does not vibrate on web when the device cannot vibrate', () async {
      final driver = _FakeNavigationFeedbackDriver(hasVibrator: false);
      final service = NavigationFeedbackService(
        driver: driver,
        isWeb: true,
        platformResolver: () => TargetPlatform.android,
        selectionClick: () async {},
      );

      await service.play();

      expect(driver.hasVibratorCalls, 1);
      expect(driver.vibrateCalls, 0);
    });
  });
}

class _FakeNavigationFeedbackDriver implements NavigationFeedbackDriver {
  _FakeNavigationFeedbackDriver({required this.hasVibrator});

  final bool hasVibrator;
  int hasVibratorCalls = 0;
  int vibrateCalls = 0;
  int? lastDurationMs;

  @override
  Future<bool> hasVibrationSupport() async {
    hasVibratorCalls++;
    return hasVibrator;
  }

  @override
  Future<void> vibrate({required int durationMs}) async {
    vibrateCalls++;
    lastDurationMs = durationMs;
  }
}
