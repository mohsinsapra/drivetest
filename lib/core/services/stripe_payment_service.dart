import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:taxi_exam_app/features/payment/web_payment_dialog.dart';
import 'package:taxi_exam_app/features/payment/payment_method_sheet.dart';
import 'package:vibration/vibration.dart';

/// Unified Stripe payment entry point for the whole app.
///
/// On **web**: skips method selection, goes directly to the CardField dialog.
/// On **mobile**: shows the method-selection bottom sheet then the native
/// payment sheet (with Apple Pay / Google Pay where available).
///
/// [createIntent] is called after the user confirms their intent to pay.
/// It must return the Stripe `clientSecret`.
///
/// Throws [stripe.StripeException] on cancellation or failure so callers
/// can distinguish cancelled (silent) from real errors.
Future<void> processStripePayment(
  BuildContext context, {
  required Future<String> Function() createIntent,
  required String merchantName,
  required String subtitle,
  required String displayAmount,
  String currency = 'SEK',
}) async {
  if (kIsWeb) {
    final secret = await createIntent();
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    await showWebPaymentDialog(
      context,
      clientSecret: secret,
      merchantName: merchantName,
      subtitle: subtitle,
      amount: displayAmount,
      currency: currency,
    );
  } else {
    await _mobilePayment(
      context,
      createIntent: createIntent,
      merchantName: merchantName,
    );
    await _hapticFeedback();
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────

Future<void> _mobilePayment(
  BuildContext context, {
  required Future<String> Function() createIntent,
  required String merchantName,
}) async {
  final method = await _pickPaymentMethod(context);
  if (method == null) {
    // User dismissed the sheet without selecting
    throw stripe.StripeException(
      error: const stripe.LocalizedErrorMessage(
        localizedMessage: 'cancelled',
        code: stripe.FailureCode.Canceled,
      ),
    );
  }

  final secret = await createIntent();

  await stripe.Stripe.instance.initPaymentSheet(
    paymentSheetParameters: stripe.SetupPaymentSheetParameters(
      paymentIntentClientSecret: secret,
      merchantDisplayName: merchantName,
      style: ThemeMode.light,
    ),
  );
  await stripe.Stripe.instance.presentPaymentSheet();
}

Future<String?> _pickPaymentMethod(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => PaymentMethodSheet(
      onSelected: (method) => Navigator.of(context).pop(method),
    ),
  );
}

// ── Haptic / vibration ────────────────────────────────────────────────────────

Future<void> _hapticFeedback() async {
  if (kIsWeb) return;
  if (Platform.isIOS) {
    HapticFeedback.mediumImpact();
  } else if (Platform.isAndroid) {
    final has = await Vibration.hasVibrator();
    if (has == true) Vibration.vibrate(duration: 300);
  }
}
