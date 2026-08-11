import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/purchase_receipt.dart';
import 'package:taxi_exam_app/core/services/iap_service.dart';
import 'package:taxi_exam_app/core/services/stripe_payment_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/core/widgets/app_dialogs.dart';
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
    Future<Map<String, dynamic>?> Function(String intentId)?
        onStripePaymentConfirmed,
    Future<Map<String, dynamic>?> Function(
            dynamic product, String? transactionId)?
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
    Future<Map<String, dynamic>?> Function(String intentId)?
        onStripePaymentConfirmed,
    Future<Map<String, dynamic>?> Function(
            dynamic product, String? transactionId)?
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
    Future<Map<String, dynamic>?> Function(String intentId)?
        onStripePaymentConfirmed,
    Future<Map<String, dynamic>?> Function(
            dynamic product, String? transactionId)?
        onIAPPurchaseConfirmed,
    required String merchantName,
  }) async {
    final product = products.first;
    final iapId = product['iap_product_id']?.toString();
    final useIAP =
        !kIsWeb && Platform.isIOS && iapId != null && iapId.isNotEmpty;

    final name = _name(products);
    final price = products.length == 1
        ? product['price']?.toString() ?? ''
        : _sum(products).toStringAsFixed(2);
    final currency = product['currency']?.toString() ?? 'SEK';
    final durationDays = _maxDays(products);
    final productId = (product['id'] as num?)?.toInt() ?? 0;

    try {
      // Apple requires all digital purchases on iOS to go through StoreKit IAP.
      // Throwing inside the try block ensures the error snackbar is shown.
      if (!kIsWeb && Platform.isIOS && !useIAP) {
        throw Exception('This product is not available for purchase on iOS.');
      }

      // Client-side fallback receipt number — used only if the backend does not
      // return one in the confirm response.
      final fallbackReceiptNumber = PurchaseReceipt.generateReceiptNumber();

      String transactionRef = '';
      Map<String, dynamic>? backendData;

      if (useIAP) {
        debugPrint('[Payment] IAP $iapId');
        IAPService.instance.init();
        final found = await IAPService.instance.loadProducts({iapId});
        if (found.isEmpty) throw Exception('Product not available in store');
        final internalId = (product['id'] as num?)?.toInt();
        transactionRef = await IAPService.instance.buyProduct(
              found.first,
              internalProductId: internalId,
            ) ??
            '';
        if (onIAPPurchaseConfirmed != null) {
          try {
            backendData = await onIAPPurchaseConfirmed(
              product,
              transactionRef.isNotEmpty ? transactionRef : null,
            );
            debugPrint('[Payment] IAP backend confirmation succeeded');
          } catch (e, st) {
            debugPrint('[Payment] IAP backend confirmation failed: $e');
            unawaited(Sentry.captureException(e,
                stackTrace: st,
                hint: Hint.withMap({'where': 'iap_backend_confirmation'})));
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
        transactionRef = intentId ?? '';
        if (intentId != null && onStripePaymentConfirmed != null) {
          try {
            backendData = await onStripePaymentConfirmed(intentId!);
          } catch (_) {}
        }
      }

      // Backend generates the canonical receipt number; fall back to client-side
      // if the backend does not return one (e.g. older server version).
      final receiptNumber =
          backendData?['receipt_number']?.toString() ?? fallbackReceiptNumber;

      // Build and persist the receipt.
      final receipt = PurchaseReceipt(
        receiptNumber: receiptNumber,
        productName: name,
        productId: productId,
        amount: price,
        currency: currency,
        durationDays: durationDays,
        purchasedAt: DateTime.now(),
        transactionRef: transactionRef,
        paymentMethod: useIAP ? 'iap' : 'stripe',
        backendRef: backendData?['receipt_number']?.toString() ??
            backendData?['subscription_id']?.toString(),
      );
      _saveReceipt(receipt);

      if (!context.mounted) return null;
      return showSubscriptionSuccess(context,
          productName: name,
          duration: _duration(durationDays),
          amount: price,
          currency: currency,
          receipt: receipt);
    } catch (e, st) {
      if (!context.mounted) return null;
      if (isIAPCancellation(e)) return null;
      if (isIAPOwnedByOtherAccount(e)) {
        final t = Translations.of(context);
        await showAppInfoDialog(
          context: context,
          icon: Icons.info_outline_rounded,
          title: t.iap_owned_by_other_title,
          body: t.iap_owned_by_other_body,
          ctaLabel: t.iap_owned_by_other_ok,
        );
        return null;
      }
      if (e is stripe.StripeException) {
        final msg = e.error.localizedMessage ?? '';
        if (!msg.toLowerCase().contains('cancel')) {
          unawaited(Sentry.captureMessage(
            'Stripe payment error: code=${e.error.code} message=$msg',
            level: SentryLevel.error,
          ));
          showAppSnackBar(msg, type: SnackBarType.error);
        }
        return null;
      }
      debugPrint('[Payment] unexpected error: $e\n$st');
      unawaited(Sentry.captureException(e,
          stackTrace: st,
          hint: Hint.withMap({'where': 'payment_coordinator'})));
      showAppSnackBar(Translations.of(context).bcd_payment_failed,
          type: SnackBarType.error);
      return null;
    }
  }

  static void _saveReceipt(PurchaseReceipt receipt) {
    AppStorage.receiptsBox().then((box) {
      box.put(receipt.receiptNumber, receipt.toJsonString());
    }).catchError((e) {
      debugPrint('[Payment] failed to save receipt: $e');
    });
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
