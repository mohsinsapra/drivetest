import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/services/app_review_service.dart';

// Minimal fake that records calls without hitting a platform channel.
class _FakeReview implements InAppReview {
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => requestCount++;

  @override
  Future<void> openStoreListing(
      {String? appStoreId, String? microsoftStoreId}) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('maybeRequestAfterExam', () {
    test('requests review and sets flag on first call', () async {
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.maybeRequestAfterExam(hasPassed: true);

      expect(fake.requestCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('review_first_exam_shown'), true);
    });

    test('does NOT request review if flag already set', () async {
      SharedPreferences.setMockInitialValues({
        'review_first_exam_shown': true,
      });
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.maybeRequestAfterExam(hasPassed: true);

      expect(fake.requestCount, 0);
    });

    test('does NOT request review when hasPassed is false', () async {
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.maybeRequestAfterExam(hasPassed: false);

      expect(fake.requestCount, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('review_first_exam_shown'), isNull);
    });
  });

  group('recordOpenAndMaybeRequest', () {
    test('increments usage day count on first open', () async {
      final svc = AppReviewService.forTest(_FakeReview());
      await svc.recordOpenAndMaybeRequest();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review_usage_day_count'), 1);
    });

    test('does not increment count when called twice same day', () async {
      final svc = AppReviewService.forTest(_FakeReview());
      await svc.recordOpenAndMaybeRequest();
      await svc.recordOpenAndMaybeRequest();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review_usage_day_count'), 1);
    });

    test('fires review when usage days reaches threshold', () async {
      SharedPreferences.setMockInitialValues({
        'review_usage_day_count': 2,
        'review_last_prompted_day_count': 0,
        'review_next_threshold': 3,
        'review_last_open_date': '2000-01-01',
      });
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.recordOpenAndMaybeRequest();

      expect(fake.requestCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review_last_prompted_day_count'), 3);
      expect([3, 5, 7], contains(prefs.getInt('review_next_threshold')));
    });

    test('does NOT fire review when below threshold', () async {
      SharedPreferences.setMockInitialValues({
        'review_usage_day_count': 1,
        'review_last_prompted_day_count': 0,
        'review_next_threshold': 5,
        'review_last_open_date': '2000-01-01',
      });
      final fake = _FakeReview();
      final svc = AppReviewService.forTest(fake);
      await svc.recordOpenAndMaybeRequest();

      expect(fake.requestCount, 0);
    });

    test('review does not propagate exceptions', () async {
      final svc = AppReviewService.forTest(_ThrowingReview());
      await expectLater(svc.maybeRequestAfterExam(hasPassed: true), completes);
    });
  });
}

class _ThrowingReview implements InAppReview {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> requestReview() async => throw Exception('platform error');
  @override
  Future<void> openStoreListing(
      {String? appStoreId, String? microsoftStoreId}) async {}
}
