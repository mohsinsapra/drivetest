import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/iap_service.dart';
import 'package:taxi_exam_app/core/services/stripe_payment_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/payment/paywall_sheet.dart';
import 'package:taxi_exam_app/features/payment/subscription_success_overlay.dart';

class PaymentCoordinator {
  PaymentCoordinator._();

  /// Shows PaywallSheet → routes IAP/Stripe → shows success overlay.
  /// Returns SubscriptionSuccessResult or null (dismissed / cancelled / error).
  static Future<SubscriptionSuccessResult?> show(
    BuildContext context, {
    required List<dynamic> products,
    required Future<String> Function(dynamic product) createStripeIntent,
    Future<void> Function(String intentId)? onStripePaymentConfirmed,
    Future<void> Function(dynamic product, String? transactionId)?
        onIAPPurchaseConfirmed,
    String? title,
    String merchantName = 'Drive Test',
  }) async {
    final product =
        await showPaywallSheet(context, products: products, title: title);
    if (product == null || !context.mounted) return null;
    return _process(context,
        products: [product],
        createStripeIntent: (prods) => createStripeIntent(prods.first),
        onStripePaymentConfirmed: onStripePaymentConfirmed,
        onIAPPurchaseConfirmed: onIAPPurchaseConfirmed,
        merchantName: merchantName);
  }

  /// Routes IAP/Stripe for pre-selected products (no paywall shown).
  static Future<SubscriptionSuccessResult?> pay(
    BuildContext context, {
    required List<dynamic> products,
    required Future<String> Function(List<dynamic> products) createStripeIntent,
    Future<void> Function(String intentId)? onStripePaymentConfirmed,
    Future<void> Function(dynamic product, String? transactionId)?
        onIAPPurchaseConfirmed,
    String merchantName = 'Drive Test',
  }) =>
      _process(context,
          products: products,
          createStripeIntent: createStripeIntent,
          onStripePaymentConfirmed: onStripePaymentConfirmed,
          onIAPPurchaseConfirmed: onIAPPurchaseConfirmed,
          merchantName: merchantName);

  static Future<SubscriptionSuccessResult?> _process(
    BuildContext context, {
    required List<dynamic> products,
    required Future<String> Function(List<dynamic>) createStripeIntent,
    Future<void> Function(String)? onStripePaymentConfirmed,
    Future<void> Function(dynamic, String?)? onIAPPurchaseConfirmed,
    required String merchantName,
  }) async {
    final product = products.first;
    final iapId = product['iap_product_id']?.toString();
    final useIAP =
        !kIsWeb && Platform.isIOS && iapId != null && iapId.isNotEmpty;

    // Apple requires all digital purchases on iOS to go through StoreKit IAP.
    // If a product has no IAP product ID configured, block the purchase rather
    // than silently falling through to Stripe (Guideline 3.1.1).
    if (!kIsWeb && Platform.isIOS && !useIAP) {
      throw Exception('This product is not available for purchase on iOS.');
    }

    final name = _name(products);
    final price = products.length == 1
        ? product['price']?.toString() ?? ''
        : _sum(products).toStringAsFixed(2);
    final currency = product['currency']?.toString() ?? 'SEK';

    try {
      if (useIAP) {
        debugPrint('[Payment] IAP $iapId');
        IAPService.instance.init();
        final found = await IAPService.instance.loadProducts({iapId});
        if (found.isEmpty) throw Exception('Product not available in store');
        final internalId = (product['id'] as num?)?.toInt();
        final transactionId = await IAPService.instance.buyProduct(
          found.first,
          internalProductId: internalId,
        );
        if (onIAPPurchaseConfirmed != null) {
          try {
            await onIAPPurchaseConfirmed(product, transactionId);
            debugPrint('[Payment] IAP backend confirmation succeeded');
          } catch (e) {
            debugPrint('[Payment] IAP backend confirmation failed: $e');
          }
        }
      } else {
        String? intentId;
        await processStripePayment(context, createIntent: () async {
          final secret = await createStripeIntent(products);
          intentId = secret.split('_secret_').first;
          return secret;
        },
            merchantName: merchantName,
            subtitle: name,
            displayAmount: price,
            currency: currency);
        if (intentId != null && onStripePaymentConfirmed != null) {
          try {
            await onStripePaymentConfirmed(intentId!);
          } catch (_) {}
        }
      }

      if (!context.mounted) return null;
      return showSubscriptionSuccess(context,
          productName: name,
          duration: _duration(_maxDays(products)),
          amount: price,
          currency: currency);
    } catch (e, st) {
      if (!context.mounted) return null;
      if (isIAPCancellation(e)) return null;
      if (e is stripe.StripeException) {
        final msg = e.error.localizedMessage ?? '';
        if (!msg.toLowerCase().contains('cancel')) {
          showAppSnackBar(msg, type: SnackBarType.error);
        }
        return null;
      }
      debugPrint('[Payment] unexpected error: $e\n$st');
      showAppSnackBar(Translations.of(context).bcd_payment_failed,
          type: SnackBarType.error);
      return null;
    }
  }

  static String _name(List<dynamic> p) => p.length == 1
      ? p.first['name']?.toString() ?? 'Subscription'
      : p
          .map((x) => x['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .join(' & ');

  static double _sum(List<dynamic> p) => p.fold(0.0, (s, x) {
        final v = x['price']?.toString().replaceAll(',', '.').trim() ?? '';
        return s + (double.tryParse(v) ?? 0.0);
      });

  static int _maxDays(List<dynamic> p) => p.fold(0, (m, x) {
        final d = (x['duration_days'] as num?)?.toInt() ?? 0;
        return d > m ? d : m;
      });

  static String? _duration(int days) {
    if (days <= 0) return null;
    if (days >= 365) return '${(days / 365).round()} year';
    if (days >= 30) return '${(days / 30).round()} months';
    return '$days days';
  }
}
