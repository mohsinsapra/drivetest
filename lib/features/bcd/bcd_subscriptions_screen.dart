import 'package:taxi_exam_app/features/payment/subscription_success_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/stripe_payment_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'bcd_category_hub_screen.dart';
import 'bcd_sub_category_screen.dart';

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
        showAppSnackBar(Translations.of(context).bcd_failed_plans, type: SnackBarType.error);
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
      final price = product['price']?.toString() ?? '';
      final currency = product['currency']?.toString() ?? 'SEK';
      final name = product['name']?.toString() ?? 'Subscription';

      await processStripePayment(
        context,
        createIntent: () => _api.createBCDPaymentIntent(product['id'] as int),
        merchantName: 'Drive Test',
        subtitle: name,
        displayAmount: price,
        currency: currency,
      );

      if (!mounted) return;
      // Optimistic update: immediately mark this product as owned.
      final durationDays = product['duration_days'] as int?;
      setState(() {
        _mySubscriptions = [
          ..._mySubscriptions,
          {
            'product': product,
            'status': 'paid',
            'end_date': DateTime.now()
                .add(Duration(days: durationDays ?? 30))
                .toIso8601String(),
          },
        ];
        _tabController.animateTo(1);
      });
      final durationLabel = durationDays != null
          ? (durationDays >= 365
              ? '${(durationDays / 365).round()} year'
              : durationDays >= 30
                  ? '${(durationDays / 30).round()} months'
                  : '$durationDays days')
          : null;
      await showSubscriptionSuccess(
        context,
        productName: name,
        duration: durationLabel,
        amount: price,
        currency: currency,
      );
      // Reload after overlay closes to sync webhook-updated status.
      if (!mounted) return;
      await _loadMine();
    } on stripe.StripeException catch (e) {
      if (!mounted) return;
      final msg = e.error.localizedMessage ?? 'Payment cancelled';
      if (!msg.toLowerCase().contains('cancel')) {
        showAppSnackBar(msg, type: SnackBarType.error);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(Translations.of(context).bcd_payment_failed, type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  bool _navigating = false;

  Future<void> _handleSubscriptionTap(dynamic sub) async {
    if (_navigating) return;
    final product = sub['product'];
    if (product == null) return;

    final rawIds = sub['subscribed_category_bcd_ids'];
    final ids = rawIds is List ? rawIds : <dynamic>[];
    if (ids.isEmpty) {
      showAppSnackBar(Translations.of(context).bcd_no_categories_linked);
      return;
    }

    final bcdId = ids.first as int;
    final productName = product['name']?.toString() ?? 'Subscription';

    setState(() => _navigating = true);
    try {
      // Fetch root categories (backend-cached) to resolve has_children
      final categories = await _api.fetchBCDAllCategories();
      if (!mounted) return;

      final match = categories.cast<Map<String, dynamic>>().firstWhere(
        (c) => c['bcd_id'] == bcdId,
        orElse: () => <String, dynamic>{},
      );

      final Map<String, dynamic> cat;
      if (match.isNotEmpty) {
        cat = Map<String, dynamic>.from(match);
        cat['is_subscribed'] = true;
      } else {
        cat = {'bcd_id': bcdId, 'name': productName, 'is_subscribed': true};
      }

      final hasChildren = cat['has_children'] == true;
      final route = hasChildren
          ? AppPageRoute(builder: (_) => BCDSubCategoryScreen(parentCategory: cat))
          : AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat));

      Navigator.push(context, route);
    } catch (_) {
      if (mounted) showAppSnackBar(Translations.of(context).bcd_failed_category, type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.of(context).bcd_subscriptions),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: Translations.of(context).bcd_plans_tab),
            Tab(text: Translations.of(context).bcd_my_subscriptions_tab),
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
            onTap: _handleSubscriptionTap,
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
        child: Text(Translations.of(context).bcd_no_plans,
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
        color: Theme.of(context).cardColor,
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
                    child: Text(Translations.of(context).bcd_active_label,
                        style: const TextStyle(
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
                    '$price SEK',
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
                          : Text(Translations.of(context).bcd_subscribe_btn),
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
  final Future<void> Function(dynamic sub) onTap;

  const _MySubscriptionsTab({
    required this.loading,
    required this.subscriptions,
    required this.onRefresh,
    required this.onTap,
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
              Text(Translations.of(context).bcd_no_active_subscriptions,
                  style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(Translations.of(context).bcd_browse_plans,
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
        itemBuilder: (ctx, i) => _SubscriptionTile(
          sub: subscriptions[i],
          onTap: () => onTap(subscriptions[i]),
        ),
      ),
    );
  }
}

/* ── Subscription tile ─────────────────────────────────────────────────────── */

class _SubscriptionTile extends StatelessWidget {
  final dynamic sub;
  final VoidCallback onTap;
  const _SubscriptionTile({required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = sub['status']?.toString() ?? '';
    final endDate = sub['end_date']?.toString() ?? '';
    final product = sub['product'];
    final productName = (product is Map ? product['name']?.toString() : null) ?? 'Plan';

    final t = Translations.of(context);
    final isActive = status == 'paid';
    final statusColor = isActive ? const Color(0xFF059669) : Colors.grey;
    final statusLabel = isActive ? t.bcd_active_label : _capitalize(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF059669).withValues(alpha: 0.3)
                  : Theme.of(context).dividerColor,
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
                        '${t.bcd_expires} ${_formatDate(endDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
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
