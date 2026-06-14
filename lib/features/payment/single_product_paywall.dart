import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/payment_coordinator.dart';

/// Shows a paywall scoped to a single BCD subscription product and returns
/// `true` if the user completed a purchase.
///
/// [subscriptionProduct] is the lightweight `subscription_product` map embedded
/// in the bcd_dashboard (it omits `iap_product_id`, so we always fetch the full
/// product list and match by `id` for iOS IAP support). [title] is shown as the
/// paywall heading — pass the category/exam name so the user sees only the one
/// product relevant to what they tapped.
Future<bool> showSingleProductPaywall(
  BuildContext context, {
  required Map<String, dynamic>? subscriptionProduct,
  required String title,
}) async {
  final api = ApiService();
  List<dynamic> products;
  try {
    final all = await api.fetchBCDSubscriptionProducts();
    if (subscriptionProduct != null) {
      final productId = subscriptionProduct['id'];
      final matched = all.where((p) => p['id'] == productId).toList();
      products = matched.isNotEmpty ? matched : all;
    } else {
      products = all;
    }
  } catch (_) {
    products = subscriptionProduct != null ? [subscriptionProduct] : const [];
  }

  if (!context.mounted || products.isEmpty) return false;

  final result = await PaymentCoordinator.show(
    context,
    products: products,
    title: title,
    createStripeIntent: (p) => api.createBCDPaymentIntent(p['id'] as int),
    onStripePaymentConfirmed: api.confirmBCDPayment,
    onIAPPurchaseConfirmed: (p, transactionId) => api.confirmBCDIAPPurchase(
      (p['id'] as num).toInt(),
      transactionId: transactionId,
    ),
  );

  if (result == null) return false;
  await DioClient().clearCache();
  BcdCache.instance.invalidate();
  await BcdCache.instance.ensureLoaded();
  return true;
}
