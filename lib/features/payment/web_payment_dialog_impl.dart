import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_stripe_web/flutter_stripe_web.dart' show WebStripe;

Future<void> showWebPaymentDialogImpl(
  BuildContext context, {
  required String clientSecret,
  required String merchantName,
  required String amount,
  required String subtitle,
  String currency = 'SEK',
}) async {
  final result = await Navigator.of(context).push<bool>(
    AppPageRoute(
      fullscreenDialog: true,
      builder: (_) => _WebPaymentPage(
        clientSecret: clientSecret,
        merchantName: merchantName,
        amount: amount,
        subtitle: subtitle,
        currency: currency,
      ),
    ),
  );
  if (result != true) {
    throw const stripe.StripeException(
      error: stripe.LocalizedErrorMessage(
        localizedMessage: 'cancelled',
        code: stripe.FailureCode.Canceled,
      ),
    );
  }
}

class _WebPaymentPage extends StatefulWidget {
  final String clientSecret;
  final String merchantName;
  final String amount;
  final String subtitle;
  final String currency;

  const _WebPaymentPage({
    required this.clientSecret,
    required this.merchantName,
    required this.amount,
    required this.subtitle,
    required this.currency,
  });

  @override
  State<_WebPaymentPage> createState() => _WebPaymentPageState();
}

class _WebPaymentPageState extends State<_WebPaymentPage> {
  bool _cardComplete = false;
  bool _processing = false;
  String? _error;

  Future<void> _pay() async {
    if (!_cardComplete || _processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      await WebStripe.instance.confirmPayment(
        widget.clientSecret,
        const stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on stripe.StripeException catch (e) {
      if (mounted) {
        setState(() {
          _error =
              e.error.localizedMessage ?? 'Payment failed. Please try again.';
          _processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Payment failed. Please try again.';
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.merchantName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed:
              _processing ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Complete your payment',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your card details below to complete the purchase.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subscription',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600)),
                          Flexible(
                            child: Text(
                              widget.subtitle,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600)),
                          Text(
                            '${widget.amount} ${widget.currency.toUpperCase()}',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // CardField uses a unique view type per instance — works on
                // every payment attempt, unlike PaymentElement which has a
                // fixed view type ID that can only be registered once.
                stripe.CardField(
                  onCardChanged: (details) {
                    setState(() {
                      _cardComplete = details?.complete ?? false;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppFilledButton(
                  label: Translations.of(context).btn_pay_now,
                  onPressed: (_cardComplete && !_processing) ? _pay : null,
                  loading: _processing,
                  borderRadius: 10,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
