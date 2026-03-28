// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Conditional imports: on web we get real stripe_web types; on mobile stubs.
import 'web_payment_dialog_stub.dart'
    if (dart.library.js_interop) 'web_payment_dialog_impl.dart';

/// Shows a Stripe PaymentElement dialog on web, or throws on mobile.
///
/// Returns normally on payment success, throws on failure or cancellation.
Future<void> showWebPaymentDialog(
  BuildContext context, {
  required String clientSecret,
  required String merchantName,
  required String amount,
  required String subtitle,
  String currency = 'SEK',
}) {
  assert(kIsWeb, 'showWebPaymentDialog should only be called on web');
  return showWebPaymentDialogImpl(context,
      clientSecret: clientSecret,
      merchantName: merchantName,
      amount: amount,
      subtitle: subtitle,
      currency: currency);
}
