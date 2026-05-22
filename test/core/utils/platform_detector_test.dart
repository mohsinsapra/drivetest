import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/utils/platform_detector.dart';

void main() {
  group('WebPlatform', () {
    test('enum has android, ios, and none values', () {
      expect(
          WebPlatform.values,
          containsAll([
            WebPlatform.android,
            WebPlatform.ios,
            WebPlatform.none,
          ]));
    });

    test('detectWebPlatform returns none in test environment (stub)', () {
      // The test runner is not a browser, so the stub implementation is used.
      expect(detectWebPlatform(), WebPlatform.none);
    });
  });
}
