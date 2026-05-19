import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';

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

  static const _kDeferredKey = AppStorage.kIapDeferredReceipt;

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
    _initialized = false;
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

    final param = PurchaseParam(
      productDetails: productDetails,
      applicationUserName: AppStorage.currentUserId,
    );
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
          verifyError = e;
          debugPrint('[IAP] backend verify failed: $e');
          if (e is IAPSubscriptionOwnedByOtherAccountException) {
            // Do not defer — this receipt will never succeed for the current user.
            debugPrint('[IAP] subscription owned by other account, not deferring');
          } else {
            // Save the receipt so it can be retried after re-login or network recovery.
            // Never surface this error to the user — the StoreKit transaction already succeeded.
            try {
              await _saveDeferredReceipt(purchase);
            } catch (saveErr) {
              debugPrint('[IAP] failed to save deferred receipt: $saveErr');
            }
          }
        }

        // Always finish the transaction; completePurchase errors are non-fatal
        // (local StoreKit testing can return null fields that cause plugin crashes).
        try {
          await _iap.completePurchase(purchase);
        } catch (e) {
          debugPrint('[IAP] completePurchase error (non-fatal): $e');
        }

        if (_pendingCompleter != null &&
            purchase.productID == _pendingProductId) {
          if (verifyError is IAPSubscriptionOwnedByOtherAccountException) {
            // Surface this specific error so the UI can show an actionable message.
            _pendingCompleter?.completeError(verifyError);
          } else {
            // For all other outcomes (success or transient backend error) resolve
            // as success — the StoreKit transaction completed and the receipt is
            // deferred for retry if needed.
            _pendingCompleter?.complete(purchase.purchaseID);
          }
          _pendingCompleter = null;
          _pendingProductId = null;
          _pendingInternalProductId = null;
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

  Future<void> _saveDeferredReceipt(PurchaseDetails purchase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kDeferredKey,
          jsonEncode({
            'receipt_data': purchase.verificationData.serverVerificationData,
            'product_id': purchase.productID,
            'internal_product_id': _pendingInternalProductId,
            'user_id': AppStorage.currentUserId,
          }));
      debugPrint('[IAP] deferred receipt saved for authenticated retry');
    } catch (e) {
      debugPrint('[IAP] failed to save deferred receipt: $e');
    }
  }

  /// Returns true if a deferred receipt exists for the current logged-in user.
  Future<bool> hasDeferredReceipt() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kDeferredKey);
    if (stored == null) return false;
    try {
      final data = jsonDecode(stored) as Map<String, dynamic>;
      final savedUserId = data['user_id'] as String?;
      // Purge receipts that predate the user_id field (no savedUserId) or
      // belong to a different user — never retry another user's purchase.
      if (savedUserId == null || savedUserId != AppStorage.currentUserId) {
        await prefs.remove(_kDeferredKey);
        debugPrint('[IAP] deferred receipt belongs to different user, purged');
        return false;
      }
    } catch (_) {
      await prefs.remove(_kDeferredKey);
      return false;
    }
    return true;
  }

  /// Called after login to verify any receipt that was saved during a purchase
  /// where backend verification failed (e.g. transient network error).
  /// Returns the backend response map (includes receipt_number) on success,
  /// or null if no deferred receipt exists or verification fails.
  Future<Map<String, dynamic>?> verifyDeferredReceipt() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kDeferredKey);
    if (stored == null) return null;

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(stored) as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove(_kDeferredKey);
      debugPrint('[IAP] deferred receipt was malformed JSON, purged');
      return null;
    }

    // Only retry for the user who made the original purchase.
    final savedUserId = data['user_id'] as String?;
    if (savedUserId == null || savedUserId != AppStorage.currentUserId) {
      await prefs.remove(_kDeferredKey);
      debugPrint('[IAP] deferred receipt belongs to different user, purged');
      return null;
    }

    // Local StoreKit testing produces JWS tokens that Apple's servers can't
    // verify. Use the confirm endpoint directly (no real receipt needed).
    if (kDebugMode) {
      debugPrint(
          '[IAP] debug mode: skipping Apple receipt verify for deferred receipt');
      try {
        final internalId = data['internal_product_id'] as int?;
        if (internalId != null) {
          final result = await _api.confirmBCDIAPPurchase(internalId);
          await prefs.remove(_kDeferredKey);
          debugPrint('[IAP] debug deferred confirm succeeded');
          return result;
        }
      } catch (e) {
        debugPrint('[IAP] debug deferred confirm failed: $e');
      }
      return null;
    }

    try {
      final result = await _api.verifyAppleIAP(
        receiptData: data['receipt_data'] as String,
        iapProductId: data['product_id'] as String,
        internalProductId: data['internal_product_id'] as int?,
        appUserId: AppStorage.currentUserId,
      );
      await prefs.remove(_kDeferredKey);
      debugPrint('[IAP] deferred receipt verified and cleared');
      return result;
    } catch (e) {
      debugPrint('[IAP] deferred verify failed: $e');
      return null;
    }
  }

  Future<void> _verifyOnBackend(PurchaseDetails purchase) async {
    if (kIsWeb || !Platform.isIOS) return;
    // Both `purchased` and `restored` must be verified on the backend.
    // `restored` happens when the Apple ID already owns the subscription (e.g. a
    // different app account is logged in on the same Apple ID). The backend's
    // original_transaction_id binding enforces ownership:
    //   • Same app account  → 200 idempotent, subscription already active.
    //   • Different account → 409, throws IAPSubscriptionOwnedByOtherAccountException.
    if (kDebugMode) {
      if (_pendingInternalProductId != null) {
        debugPrint(
            '[IAP] debug mode: confirming purchase on backend (no Apple verify)');
        try {
          await _api.confirmBCDIAPPurchase(_pendingInternalProductId!);
        } on DioException catch (e) {
          if (e.response?.statusCode == 409) {
            throw IAPSubscriptionOwnedByOtherAccountException();
          }
          rethrow;
        }
      } else {
        debugPrint(
            '[IAP] debug mode: skipping backend verify (no internalProductId)');
      }
      return;
    }
    try {
      await _api.verifyAppleIAP(
        receiptData: purchase.verificationData.serverVerificationData,
        iapProductId: purchase.productID,
        internalProductId: _pendingInternalProductId,
        appUserId: AppStorage.currentUserId,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw IAPSubscriptionOwnedByOtherAccountException();
      }
      rethrow;
    }
  }
}

class _PurchaseCanceledException implements Exception {
  @override
  String toString() => 'Purchase was canceled';
}

/// True if the exception represents a user-initiated cancellation.
bool isIAPCancellation(Object e) => e is _PurchaseCanceledException;

/// Thrown when the backend returns 409 — the Apple transaction's
/// original_transaction_id is already bound to a different app account.
class IAPSubscriptionOwnedByOtherAccountException implements Exception {
  @override
  String toString() => 'Subscription is linked to a different account';
}

/// True if the exception means the subscription belongs to another app account.
bool isIAPOwnedByOtherAccount(Object e) =>
    e is IAPSubscriptionOwnedByOtherAccountException;
