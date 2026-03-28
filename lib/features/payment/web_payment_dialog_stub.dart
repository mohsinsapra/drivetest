import 'package:flutter/material.dart';

Future<void> showWebPaymentDialogImpl(
  BuildContext context, {
  required String clientSecret,
  required String merchantName,
  required String amount,
  required String subtitle,
  String currency = 'SEK',
}) {
  throw UnsupportedError('Web payment dialog is only supported on web');
}
