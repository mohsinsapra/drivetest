import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:taxi_exam_app/core/monitoring/safe_flutter_error_handler.dart';

void main() {
  final originalHandler = FlutterError.onError;

  tearDown(() {
    FlutterError.onError = originalHandler;
  });

  group('installSafeFlutterErrorHandler', () {
    test('does not replace the error handler outside web', () {
      void handler(FlutterErrorDetails details) {}

      FlutterError.onError = handler;

      installSafeFlutterErrorHandler(isWeb: false);

      expect(FlutterError.onError, same(handler));
    });

    test('passes through when the existing handler succeeds', () {
      var calls = 0;
      var captureCalls = 0;
      FlutterError.onError = (details) {
        calls++;
      };

      installSafeFlutterErrorHandler(
        isWeb: true,
        captureException: (exception, {stackTrace, hint}) async {
          captureCalls++;
        },
      );

      FlutterError.onError!(FlutterErrorDetails(exception: StateError('boom')));

      expect(calls, 1);
      expect(captureCalls, 0);
    });

    test('captures the original error if the existing handler throws',
        () async {
      final originalException = StateError('original');
      final originalStackTrace = StackTrace.current;
      Object? capturedException;
      StackTrace? capturedStackTrace;
      Hint? capturedHint;
      var presentCalls = 0;

      FlutterError.onError = (details) {
        throw TypeError();
      };

      installSafeFlutterErrorHandler(
        isWeb: true,
        captureException: (exception, {stackTrace, hint}) async {
          capturedException = exception;
          capturedStackTrace = stackTrace;
          capturedHint = hint;
        },
        presentError: (details) {
          presentCalls++;
        },
      );

      FlutterError.onError!(
        FlutterErrorDetails(
          exception: originalException,
          stack: originalStackTrace,
        ),
      );

      expect(presentCalls, 1);
      expect(capturedException, same(originalException));
      expect(capturedStackTrace, same(originalStackTrace));
      expect(capturedHint, isNotNull);
      expect(
        capturedHint!.get(TypeCheckHint.syntheticException),
        isA<FlutterErrorDetails>(),
      );
    });
  });
}
