import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';

/// Wraps [InAppPurchase] and wires purchases through backend validation.
///
/// Usage:
///   1. Call [loadProducts] with the iap_product_id values from the API.
///   2. Call [buyProduct] when the user selects a plan.
///   3. Observe [purchaseStream] or await [buyProduct] for the result.
class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  final _api = ApiService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Completer for the currently in-flight purchase.
  // Completes with the StoreKit transaction_id (purchaseID) on success.
  Completer<String?>? _pendingCompleter;
  String? _pendingProductId;
  int? _pendingInternalProductId;

  bool _initialized = false;

  // Broadcast stream that emits each successfully restored product ID.
  final _restoreController = StreamController<String>.broadcast();
  Stream<String> get restoredProductIds => _restoreController.stream;

  Future<bool> get isAvailable => _iap.isAvailable();

  /// Start listening to the purchase stream. Call once at app startup (or
  /// lazily before the first purchase).
  void init() {
    if (_initialized) return;
    _initialized = true;
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object err) {
        _pendingCompleter?.completeError(err);
        _pendingCompleter = null;
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _restoreController.close();
    _initialized = false;
  }

  /// Initialises the service (if not already) and triggers a restore.
  Future<void> restore() async {
    init();
    await _iap.restorePurchases();
  }

  /// Load [ProductDetails] for the given IAP product IDs from the store.
  Future<List<ProductDetails>> loadProducts(Set<String> productIds) async {
    final available = await _iap.isAvailable();
    debugPrint('[IAP] storeAvailable=$available');
    if (!available) throw Exception('App Store not available on this device');
    final response = await _iap.queryProductDetails(productIds);
    debugPrint(
        '[IAP] loadProducts found=${response.productDetails.length} notFound=${response.notFoundIDs} error=${response.error}');
    return response.productDetails;
  }

  /// Initiate a purchase for [productDetails] and wait for backend validation.
  /// Returns the StoreKit transaction ID (`purchaseID`) on success when
  /// available. [internalProductId] is the backend's integer product ID, sent
  /// to the verification endpoint so the server can activate the correct
  /// subscription. Throws on cancellation or error.
  Future<String?> buyProduct(ProductDetails productDetails,
      {int? internalProductId}) async {
    if (_pendingCompleter != null) {
      throw StateError('A purchase is already in progress');
    }

    _pendingCompleter = Completer<String?>();
    _pendingProductId = productDetails.id;
    _pendingInternalProductId = internalProductId;

    final param = PurchaseParam(productDetails: productDetails);
    await _iap.buyNonConsumable(purchaseParam: param);

    return _pendingCompleter!.future;
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint(
          '[IAP] purchaseUpdate id=${purchase.productID} status=${purchase.status}');
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        Object? verifyError;
        try {
          debugPrint('[IAP] verifying on backend...');
          await _verifyOnBackend(purchase);
          debugPrint('[IAP] backend verified, completing purchase');
        } catch (e) {
          debugPrint('[IAP] backend verify failed: $e');
          verifyError = e;
        }

        // Always finish the transaction; completePurchase errors are non-fatal
        // (local StoreKit testing can return null fields that cause plugin crashes).
        try {
          await _iap.completePurchase(purchase);
        } catch (e) {
          debugPrint('[IAP] completePurchase error (non-fatal): $e');
        }

        if (_pendingCompleter != null && purchase.productID == _pendingProductId) {
          // Active buy flow — resolve the completer.
          if (verifyError != null) {
            _pendingCompleter?.completeError(verifyError);
          } else {
            _pendingCompleter?.complete(purchase.purchaseID);
          }
          _pendingCompleter = null;
          _pendingProductId = null;
          _pendingInternalProductId = null;
        } else if (purchase.status == PurchaseStatus.restored && verifyError == null) {
          // Restore flow — notify listeners.
          _restoreController.add(purchase.productID);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        try {
          await _iap.completePurchase(purchase);
        } catch (_) {}
        if (purchase.productID == _pendingProductId) {
          _pendingCompleter?.completeError(
            purchase.error ?? Exception('Purchase failed'),
          );
          _pendingCompleter = null;
          _pendingProductId = null;
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (purchase.productID == _pendingProductId) {
          _pendingCompleter?.completeError(_PurchaseCanceledException());
          _pendingCompleter = null;
          _pendingProductId = null;
        }
      }
    }
  }

  Future<void> _verifyOnBackend(PurchaseDetails purchase) async {
    if (kIsWeb || !Platform.isIOS) return;
    // Local StoreKit testing produces JWS tokens that Apple's servers can't verify.
    if (kDebugMode) {
      debugPrint('[IAP] skipping backend verify in debug mode');
      return;
    }
    await _api.verifyAppleIAP(
      receiptData: purchase.verificationData.serverVerificationData,
      iapProductId: purchase.productID,
      internalProductId: _pendingInternalProductId,
    );
  }
}

class _PurchaseCanceledException implements Exception {
  @override
  String toString() => 'Purchase was canceled';
}

/// True if the exception represents a user-initiated cancellation.
bool isIAPCancellation(Object e) => e is _PurchaseCanceledException;
