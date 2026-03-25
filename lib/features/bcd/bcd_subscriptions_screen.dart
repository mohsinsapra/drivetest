import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:vibration/vibration.dart';

class BCDSubscriptionsScreen extends StatefulWidget {
  const BCDSubscriptionsScreen({super.key});

  @override
  State<BCDSubscriptionsScreen> createState() => _BCDSubscriptionsScreenState();
}

class _BCDSubscriptionsScreenState extends State<BCDSubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();

  List<dynamic> _products = [];
  List<dynamic> _mySubscriptions = [];
  bool _loadingProducts = true;
  bool _loadingMine = true;
  bool _buying = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadProducts();
    _loadMine();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _api.fetchBCDSubscriptionProducts();
      if (mounted) setState(() { _products = data; _loadingProducts = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProducts = false);
        showAppSnackBar('Failed to load plans');
      }
    }
  }

  Future<void> _loadMine() async {
    try {
      final data = await _api.fetchMyBCDSubscriptions();
      if (mounted) setState(() { _mySubscriptions = data; _loadingMine = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMine = false);
      }
    }
  }

  Future<void> _handleBuy(dynamic product) async {
    if (_buying) return;
    setState(() => _buying = true);
    try {
      final secret = await _api.createBCDPaymentIntent(product['id'] as int);
      await _processPayment(secret);
      if (!mounted) return;
      showAppSnackBar('Payment successful! Subscription activated.');
      setState(() { _loadingMine = true; });
      await _loadMine();
    } on stripe.StripeException catch (e) {
      if (!mounted) return;
      final msg = e.error.localizedMessage ?? 'Payment cancelled';
      if (!msg.toLowerCase().contains('cancel')) {
        showAppSnackBar(msg);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar('Payment failed. Please try again.');
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  Future<void> _processPayment(String clientSecret) async {
    await stripe.Stripe.instance.initPaymentSheet(
      paymentSheetParameters: stripe.SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'TaxiExam BCD',
        applePay: Platform.isIOS
            ? const stripe.PaymentSheetApplePay(merchantCountryCode: 'SE')
            : null,
        googlePay: Platform.isAndroid
            ? const stripe.PaymentSheetGooglePay(
                merchantCountryCode: 'SE', testEnv: false)
            : null,
        style: ThemeMode.light,
      ),
    );
    await stripe.Stripe.instance.presentPaymentSheet();
    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else {
      final has = await Vibration.hasVibrator();
      if (has == true) Vibration.vibrate(duration: 300);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'My Subscriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlansTab(
            loading: _loadingProducts,
            products: _products,
            mySubscriptions: _mySubscriptions,
            buying: _buying,
            onBuy: _handleBuy,
          ),
          _MySubscriptionsTab(
            loading: _loadingMine,
            subscriptions: _mySubscriptions,
            onRefresh: () async {
              setState(() => _loadingMine = true);
              await _loadMine();
            },
          ),
        ],
      ),
    );
  }
}

/* ── Plans tab ─────────────────────────────────────────────────────────────── */

class _PlansTab extends StatelessWidget {
  final bool loading;
  final List<dynamic> products;
  final List<dynamic> mySubscriptions;
  final bool buying;
  final void Function(dynamic product) onBuy;

  const _PlansTab({
    required this.loading,
    required this.products,
    required this.mySubscriptions,
    required this.buying,
    required this.onBuy,
  });

  bool _isOwned(dynamic product) {
    final productId = product['id'];
    return mySubscriptions.any((s) {
      final p = s['product'];
      final subProductId = (p is Map) ? p['id'] : p;
      return subProductId == productId && s['status'] == 'paid';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _Shimmer();

    if (products.isEmpty) {
      return Center(
        child: Text('No plans available',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (ctx, i) {
          final p = products[i];
          final owned = _isOwned(p);
          return _ProductCard(
            product: p,
            owned: owned,
            buying: buying,
            onBuy: () => onBuy(p),
          );
        },
      ),
    );
  }
}

/* ── Product card ───────────────────────────────────────────────────────────── */

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final bool owned;
  final bool buying;
  final VoidCallback onBuy;

  const _ProductCard({
    required this.product,
    required this.owned,
    required this.buying,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? 'Plan';
    final price = product['price']?.toString() ?? '';
    final durationDays = product['duration_days'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: owned
            ? Border.all(color: const Color(0xFF059669), width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    owned ? LucideIcons.checkCircle : LucideIcons.creditCard,
                    color: const Color(0xFF059669),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      if (durationDays > 0)
                        Text(
                          _formatDuration(durationDays),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
                if (owned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Active',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            if (price.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price.contains('.') || price.contains(',')
                        ? '$price SEK'
                        : '$price SEK',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  if (!owned)
                    ElevatedButton(
                      onPressed: buying ? null : onBuy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: buying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Subscribe'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int days) {
    if (days >= 365) {
      final years = (days / 365).round();
      return '$years year${years > 1 ? 's' : ''}';
    } else if (days >= 30) {
      final months = (days / 30).round();
      return '$months month${months > 1 ? 's' : ''}';
    }
    return '$days days';
  }
}

/* ── My subscriptions tab ──────────────────────────────────────────────────── */

class _MySubscriptionsTab extends StatelessWidget {
  final bool loading;
  final List<dynamic> subscriptions;
  final Future<void> Function() onRefresh;

  const _MySubscriptionsTab({
    required this.loading,
    required this.subscriptions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _Shimmer();

    if (subscriptions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.packageOpen,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No active subscriptions',
                  style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text('Browse plans to get started',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: subscriptions.length,
        itemBuilder: (ctx, i) => _SubscriptionTile(sub: subscriptions[i]),
      ),
    );
  }
}

/* ── Subscription tile ─────────────────────────────────────────────────────── */

class _SubscriptionTile extends StatelessWidget {
  final dynamic sub;
  const _SubscriptionTile({required this.sub});

  @override
  Widget build(BuildContext context) {
    final status = sub['status']?.toString() ?? '';
    final endDate = sub['end_date']?.toString() ?? '';
    final product = sub['product'];
    final productName = (product is Map ? product['name']?.toString() : null) ?? 'Plan';

    final isActive = status == 'paid';
    final statusColor = isActive ? const Color(0xFF059669) : Colors.grey;
    final statusLabel = isActive ? 'Active' : _capitalize(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFF059669).withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isActive ? LucideIcons.shieldCheck : LucideIcons.shieldOff,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (endDate.isNotEmpty)
                  Text(
                    'Expires ${_formatDate(endDate)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

/* ── Shimmer ────────────────────────────────────────────────────────────────── */

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
