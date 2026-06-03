import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/utils/in_flight_request_tracker.dart';

void main() {
  test('clears failed in-flight request without leaking an unhandled error',
      () async {
    final tracker = InFlightRequestTracker<int>();
    final completer = Completer<int>();
    final zoneErrors = <Object>[];

    await runZonedGuarded(() async {
      final first = tracker.run(() => completer.future);
      final second = tracker.run(() async => 99);
      expect(identical(first, second), isTrue);

      final expectation = expectLater(first, throwsA(isA<StateError>()));
      await Future<void>.delayed(Duration.zero);
      completer.completeError(StateError('boom'));
      await expectation;
      await Future<void>.delayed(Duration.zero);

      await expectLater(tracker.run(() async => 7), completion(7));
    }, (error, stackTrace) {
      zoneErrors.add(error);
    });

    expect(zoneErrors, isEmpty);
  });
}
