import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/services/stripe_payment_service.dart';

void main() {
  group('prepareStripeForMobilePayment', () {
    test('configures Stripe before mobile payment even without dotenv',
        () async {
      String? assignedKey;
      var applyCalls = 0;

      final configured = await prepareStripeForMobilePayment(
        defineValue: '',
        dotenvValue: null,
        assignPublishableKey: (key) => assignedKey = key,
        applySettings: () async {
          applyCalls += 1;
        },
      );

      expect(configured, isTrue);
      expect(assignedKey, isNotEmpty);
      expect(applyCalls, 1);
    });
  });
}
