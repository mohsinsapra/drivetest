import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Track when user attempts to make a purchase
  Future<void> logPurchaseAttempt({
    required String licenceId,
    required String licenceName,
    required String categoryId,
    required String categoryName,
    required double amount,
    required String currency,
  }) async {
    await _analytics.logEvent(
      name: 'purchase_attempt',
      parameters: {
        'licence_id': licenceId,
        'licence_name': licenceName,
        'category_id': categoryId,
        'category_name': categoryName,
        'value': amount,
        'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track when user clicks Buy Now button
  Future<void> logBuyNowClick({
    required String licenceId,
    required String licenceName,
    required String categoryId,
    required String categoryName,
  }) async {
    await _analytics.logEvent(
      name: 'buy_now_clicked',
      parameters: {
        'licence_id': licenceId,
        'licence_name': licenceName,
        'category_id': categoryId,
        'category_name': categoryName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track when payment sheet is opened
  Future<void> logPaymentMethodSheetOpened({
    required String licenceId,
    required String categoryId,
  }) async {
    await _analytics.logEvent(
      name: 'payment_method_sheet_opened',
      parameters: {
        'licence_id': licenceId,
        'category_id': categoryId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track when payment method is selected
  Future<void> logPaymentMethodSelected({
    required String paymentMethod,
    required String licenceId,
    required String categoryId,
  }) async {
    await _analytics.logEvent(
      name: 'payment_method_selected',
      parameters: {
        'payment_method': paymentMethod,
        'licence_id': licenceId,
        'category_id': categoryId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track successful purchase (Firebase standard event)
  Future<void> logPurchaseSuccess({
    required String licenceId,
    required String licenceName,
    required String categoryId,
    required String categoryName,
    required double amount,
    required String currency,
    required String transactionId,
  }) async {
    // Log Firebase's standard purchase event
    await _analytics.logPurchase(
      value: amount,
      currency: currency,
      items: [
        AnalyticsEventItem(
          itemId: categoryId,
          itemName: categoryName,
          itemCategory: licenceName,
          price: amount,
          quantity: 1,
        ),
      ],
    );

    // Also log custom event for detailed tracking
    await _analytics.logEvent(
      name: 'subscription_purchased',
      parameters: {
        'licence_id': licenceId,
        'licence_name': licenceName,
        'category_id': categoryId,
        'category_name': categoryName,
        'value': amount,
        'currency': currency,
        'transaction_id': transactionId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track failed purchase
  Future<void> logPurchaseFailure({
    required String licenceId,
    required String categoryId,
    required String errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'purchase_failed',
      parameters: {
        'licence_id': licenceId,
        'category_id': categoryId,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track when user cancels purchase
  Future<void> logPurchaseCancelled({
    required String licenceId,
    required String categoryId,
  }) async {
    await _analytics.logEvent(
      name: 'purchase_cancelled',
      parameters: {
        'licence_id': licenceId,
        'category_id': categoryId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track when subscription dialog is shown
  Future<void> logSubscriptionDialogShown({
    required String licenceId,
    required String categoryId,
    required String categoryName,
  }) async {
    await _analytics.logEvent(
      name: 'subscription_dialog_shown',
      parameters: {
        'licence_id': licenceId,
        'category_id': categoryId,
        'category_name': categoryName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
