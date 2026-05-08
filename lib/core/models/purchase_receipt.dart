import 'dart:convert';
import 'dart:math';

class PurchaseReceipt {
  final String receiptNumber;
  final String productName;
  final int productId;
  final String amount;
  final String currency;
  final int durationDays;
  final DateTime purchasedAt;
  final String transactionRef; // Stripe paymentIntentId or StoreKit transactionId
  final String paymentMethod;  // 'stripe' | 'iap'
  final String? backendRef;    // subscription ID returned by backend, if available

  const PurchaseReceipt({
    required this.receiptNumber,
    required this.productName,
    required this.productId,
    required this.amount,
    required this.currency,
    required this.durationDays,
    required this.purchasedAt,
    required this.transactionRef,
    required this.paymentMethod,
    this.backendRef,
  });

  static String generateReceiptNumber() {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final suffix =
        List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'RCP-$date-$suffix';
  }

  Map<String, dynamic> toJson() => {
        'receiptNumber': receiptNumber,
        'productName': productName,
        'productId': productId,
        'amount': amount,
        'currency': currency,
        'durationDays': durationDays,
        'purchasedAt': purchasedAt.toIso8601String(),
        'transactionRef': transactionRef,
        'paymentMethod': paymentMethod,
        if (backendRef != null) 'backendRef': backendRef,
      };

  factory PurchaseReceipt.fromJson(Map<String, dynamic> json) =>
      PurchaseReceipt(
        receiptNumber: json['receiptNumber'] as String,
        productName: json['productName'] as String,
        productId: (json['productId'] as num).toInt(),
        amount: json['amount'] as String,
        currency: json['currency'] as String,
        durationDays: (json['durationDays'] as num).toInt(),
        purchasedAt: DateTime.parse(json['purchasedAt'] as String),
        transactionRef: json['transactionRef'] as String,
        paymentMethod: json['paymentMethod'] as String,
        backendRef: json['backendRef'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  static PurchaseReceipt fromJsonString(String s) =>
      PurchaseReceipt.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
