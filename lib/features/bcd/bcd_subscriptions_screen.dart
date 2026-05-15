import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/payment_coordinator.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
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
  Object? _buyingProductId;

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

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    try {
      final data = await _api.fetchBCDSubscriptionProducts(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _products = data
              .whereType<Map<String, dynamic>>()
              .where((p) => p['is_active'] != false)
              .toList();
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProducts = false);
        showAppSnackBar(Translations.of(context).bcd_failed_plans,
            type: SnackBarType.error);
      }
    }
  }

  Future<void> _loadMine({bool forceRefresh = false}) async {
    try {
      final data =
          await _api.fetchMyBCDSubscriptions(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _mySubscriptions = data;
          _loadingMine = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMine = false);
      }
    }
  }

  Future<void> _handleFreeAccess(dynamic product) async {
    final rawIds = product['category_bcd_ids'];
    final ids = rawIds is List ? rawIds : <dynamic>[];
    if (ids.isEmpty) {
      showAppSnackBar(Translations.of(context).bcd_no_categories_linked);
      return;
    }
    final bcdId = ids.first as int;
    final productName = product['name']?.toString() ?? 'Subscription';
    try {
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
          ? AppPageRoute(
              builder: (_) => BCDSubCategoryScreen(parentCategory: cat))
          : AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat));
      Navigator.push(context, route);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_category,
            type: SnackBarType.error);
      }
    }
  }

  Future<void> _handleBuy(dynamic product) async {
    if (_buyingProductId != null) return;
    final productId = product['id']?.toString();
    final alreadyOwned = productId != null &&
        _mySubscriptions.any((s) {
          final p = s['product'];
          final subProductId = ((p is Map) ? p['id'] : p)?.toString();
          return subProductId == productId && s['status'] == 'paid';
        });
    if (alreadyOwned) {
      await _handleFreeAccess(product);
      return;
    }
    setState(() => _buyingProductId = product['id']);
    try {
      final result = await PaymentCoordinator.pay(
        context,
        products: [product],
        createStripeIntent: (_) =>
            _api.createBCDPaymentIntent(product['id'] as int),
        onIAPPurchaseConfirmed: (p, transactionId) =>
            _api.confirmBCDIAPPurchase(
          (p['id'] as num).toInt(),
          transactionId: transactionId,
        ),
      );
      if (result == null || !mounted) return;
      final days = product['duration_days'] as int?;
      setState(() {
        _mySubscriptions = [
          ..._mySubscriptions,
          {
            'product': product,
            'status': 'paid',
            'end_date': DateTime.now()
                .add(Duration(days: days ?? 30))
                .toIso8601String(),
          },
        ];
        _tabController.animateTo(1);
      });
      if (!mounted) return;
      await _loadMine();
    } finally {
      if (mounted) setState(() => _buyingProductId = null);
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
          ? AppPageRoute(
              builder: (_) => BCDSubCategoryScreen(parentCategory: cat))
          : AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat));

      Navigator.push(context, route);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_category,
            type: SnackBarType.error);
      }
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
            buyingProductId: _buyingProductId,
            onBuy: _handleBuy,
            onFreeAccess: _handleFreeAccess,
            onStartPractice: _handleFreeAccess,
            onRefresh: () async {
              setState(() => _loadingProducts = true);
              await _loadProducts(forceRefresh: true);
            },
          ),
          _MySubscriptionsTab(
            loading: _loadingMine,
            subscriptions: _mySubscriptions,
            onRefresh: () async {
              setState(() => _loadingMine = true);
              await _loadMine(forceRefresh: true);
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
  final Object? buyingProductId;
  final void Function(dynamic product) onBuy;
  final void Function(dynamic product) onFreeAccess;
  final void Function(dynamic product) onStartPractice;
  final Future<void> Function() onRefresh;

  const _PlansTab({
    required this.loading,
    required this.products,
    required this.mySubscriptions,
    required this.buyingProductId,
    required this.onBuy,
    required this.onFreeAccess,
    required this.onStartPractice,
    required this.onRefresh,
  });

  bool _isOwned(dynamic product) {
    if (product['is_free'] == true) return true;
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
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (ctx, i) {
          final p = products[i];
          final owned = _isOwned(p);
          final isFree = p['is_free'] == true;
          return _ProductCard(
            product: p,
            owned: owned,
            isFree: isFree,
            buying: buyingProductId == p['id'],
            disabled: buyingProductId != null,
            onBuy: () => onBuy(p),
            onFreeAccess: () => onFreeAccess(p),
            onStartPractice: () => onStartPractice(p),
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
  final bool isFree;
  final bool buying;
  final bool disabled;
  final VoidCallback onBuy;
  final VoidCallback onFreeAccess;
  final VoidCallback onStartPractice;

  const _ProductCard({
    required this.product,
    required this.owned,
    required this.isFree,
    required this.buying,
    required this.disabled,
    required this.onBuy,
    required this.onFreeAccess,
    required this.onStartPractice,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final name = product['name']?.toString() ?? 'Plan';
    final price = product['price']?.toString() ?? '';
    final currency = product['currency']?.toString() ?? 'SEK';
    final durationDays = product['duration_days'] as int? ?? 0;
    final durationLabel =
        durationDays > 0 ? _formatDuration(durationDays) : null;

    final accentColor = (owned || isFree) ? cs.secondary : categoryColor(name);
    final iconData = owned ? LucideIcons.checkCircle : categoryIcon(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: owned
              ? cs.secondary.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.4),
          width: owned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData, color: accentColor, size: 24),
                ),
                const Spacer(),
                if (isFree || owned)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFree
                          ? Translations.of(context).bcd_free_label
                          : Translations.of(context).bcd_active_label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.secondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                else if (durationLabel != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      durationLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            if (isFree || owned)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isFree ? onFreeAccess : onStartPractice,
                  icon: const Icon(LucideIcons.bookOpenCheck, size: 16),
                  label: Text(Translations.of(context).bcd_start_practice),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.secondary.withValues(alpha: 0.85),
                    foregroundColor: cs.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (price.isNotEmpty)
                    Text(
                      '$price $currency',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  FilledButton(
                    onPressed: disabled ? null : onBuy,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary.withValues(alpha: 0.9),
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: buying
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.onPrimary))
                        : Text(
                            Translations.of(context).bcd_subscribe_btn,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
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
      final cs = Theme.of(context).colorScheme;
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.packageOpen,
                  size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(Translations.of(context).bcd_no_plans,
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(Translations.of(context).bcd_browse_plans,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
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

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final status = sub['status']?.toString() ?? '';
    final endDate = sub['end_date']?.toString() ?? '';
    final product = sub['product'];
    final productName =
        (product is Map ? product['name']?.toString() : null) ?? 'Plan';

    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);
    final isActive = status == 'paid';
    final isExpired = status == 'expired' || _isDateExpired(endDate);

    final statusColor = isActive
        ? cs.secondary
        : isExpired
            ? cs.error.withValues(alpha: 0.8)
            : cs.onSurfaceVariant;
    final statusLabel = isActive
        ? t.bcd_active_label
        : isExpired
            ? 'Expired'
            : _capitalize(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: isExpired ? 0.65 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? cs.secondary.withValues(alpha: 0.3)
                    : isExpired
                        ? cs.error.withValues(alpha: 0.2)
                        : cs.outlineVariant,
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
                      Text(
                        productName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isExpired ? cs.onSurfaceVariant : cs.onSurface,
                        ),
                      ),
                      if (endDate.isNotEmpty)
                        Text(
                          _expiryLabel(endDate, isActive),
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive && _isDueSoon(endDate)
                                ? cs.error
                                : cs.onSurfaceVariant,
                          ),
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
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight,
                      size: 16,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  bool _isDateExpired(String iso) {
    try {
      return DateTime.parse(iso).toLocal().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _isDueSoon(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = dt.difference(DateTime.now()).inDays;
      return diff >= 0 && diff <= 14;
    } catch (_) {
      return false;
    }
  }

  String _expiryLabel(String iso, bool isActive) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = dt.difference(now);
      final dateStr = '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

      if (!isActive) return 'Expired $dateStr';

      if (diff.inDays < 0) return 'Expired $dateStr';
      if (diff.inDays == 0) return 'Expires today';
      if (diff.inDays == 1) return 'Expires tomorrow';
      if (diff.inDays <= 14) return 'Expires in ${diff.inDays} days · $dateStr';
      return 'Expires $dateStr';
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
