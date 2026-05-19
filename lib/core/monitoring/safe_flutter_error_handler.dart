import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

typedef ErrorCapture = Future<void> Function(
  Object exception, {
  StackTrace? stackTrace,
  Hint? hint,
});

typedef ErrorPresenter = void Function(FlutterErrorDetails details);

void installSafeFlutterErrorHandler({
  required bool isWeb,
  ErrorCapture? captureException,
  ErrorPresenter? presentError,
}) {
  if (!isWeb) {
    return;
  }

  final existingHandler = FlutterError.onError;
  if (existingHandler == null) {
    return;
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    try {
      existingHandler(details);
    } catch (_, stackTrace) {
      (presentError ?? FlutterError.presentError)(details);

      final hint = Hint()..addAll({TypeCheckHint.syntheticException: details});
      unawaited((captureException ?? _captureWithSentry)(
        details.exception,
        stackTrace: details.stack ?? stackTrace,
        hint: hint,
      ));
    }
  };
}

Future<void> _captureWithSentry(
  Object exception, {
  StackTrace? stackTrace,
  Hint? hint,
}) async {
  await Sentry.captureException(
    exception,
    stackTrace: stackTrace,
    hint: hint,
  );
}
