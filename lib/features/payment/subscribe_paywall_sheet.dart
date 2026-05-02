import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/stripe_payment_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/payment/subscription_success_overlay.dart';

/// Shows a bottom sheet with subscription plans that cover [category].
/// User selects a plan first, then taps the CTA to open Stripe — no navigation.
Future<void> showCategorySubscribeSheet(
  BuildContext context, {
  required Map<String, dynamic> category,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaywallSheet(category: category),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet({required this.category});
  final Map<String, dynamic> category;

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  final _api = ApiService();

  List<dynamic> _products = [];
  bool _loading = true;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final all = await _api.fetchBCDSubscriptionProducts();
      final bcdId = widget.category['bcd_id'];

      final bcdIdStr = bcdId?.toString();
      final filtered = all.where((p) {
        final rawIds = p['subscribed_category_bcd_ids'];
        if (rawIds == null) return true;
        if (rawIds is! List || rawIds.isEmpty) return true;
        return rawIds.any((id) => id.toString() == bcdIdStr);
      }).toList();

      if (mounted) {
        setState(() {
          _products = filtered.isNotEmpty ? filtered : all;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy(dynamic product) async {
    if (_buying) return;
    setState(() => _buying = true);

    final price = product['price']?.toString() ?? '';
    final currency = product['currency']?.toString() ?? 'SEK';
    final name = product['name']?.toString() ?? 'Subscription';

    try {
      String? capturedIntentId;
      await processStripePayment(
        context,
        createIntent: () async {
          final secret = await _api.createBCDPaymentIntent(product['id'] as int);
          capturedIntentId = secret.split('_secret_').first;
          return secret;
        },
        merchantName: 'Drive Test',
        subtitle: name,
        displayAmount: price,
        currency: currency,
      );

      // Immediately confirm on the backend so the subscription is PAID
      // before we call /self — don't wait for the asynchronous webhook.
      if (capturedIntentId != null) {
        try {
          await _api.confirmBCDPayment(capturedIntentId!);
        } catch (_) {
          // Non-fatal: webhook will still fire.
        }
      }

      if (!mounted) return;

      // Bust HTTP cache, re-fetch /self (subscriptions + dashboard), hydrate BcdCache.
      await DioClient().clearCache();
      BcdCache.instance.invalidate();

      await BcdCache.instance.ensureLoaded();

      if (!mounted) return;

      // Close the sheet, then show the success overlay on the caller's screen.
      Navigator.of(context).pop();

      final durationDays = product['duration_days'] as int?;
      final durationLabel = durationDays != null
          ? (durationDays >= 365
              ? '${(durationDays / 365).round()} year'
              : durationDays >= 30
                  ? '${(durationDays / 30).round()} months'
                  : '$durationDays days')
          : null;

      if (context.mounted) {
        await showSubscriptionSuccess(
          context,
          productName: name,
          duration: durationLabel,
          amount: price,
          currency: currency,
        );
      }
    } on stripe.StripeException catch (e) {
      if (!mounted) return;
      final msg = e.error.localizedMessage ?? '';
      if (!msg.toLowerCase().contains('cancel')) {
        showAppSnackBar(msg, type: SnackBarType.error);
      }
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        Translations.of(context).bcd_payment_failed,
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg =
        isDark ? theme.colorScheme.surface : theme.scaffoldBackgroundColor;
    final categoryName =
        widget.category['name']?.toString() ?? 'Subscription';
    final t = Translations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.creditCard,
                    size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      t.onb_recommendations_subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Plans
          if (_loading)
            _Shimmer(isDark: isDark)
          else if (_products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                t.bcd_no_plans,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            ...List.generate(_products.length, (i) {
              return _PlanTile(
                product: _products[i],
                buying: _buying,
                onTap: () => _buy(_products[i]),
              );
            }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selectable plan tile — tap to select, no inline buy button
// ─────────────────────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.product,
    required this.buying,
    required this.onTap,
  });

  final dynamic product;
  final bool buying;
  final VoidCallback onTap;

  String _formatDuration(int days) {
    if (days >= 365) {
      final y = (days / 365).round();
      return '$y year${y > 1 ? 's' : ''}';
    }
    if (days >= 30) {
      final m = (days / 30).round();
      return '$m month${m > 1 ? 's' : ''}';
    }
    return '$days days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = product['name']?.toString() ?? 'Plan';
    final price = product['price']?.toString() ?? '';
    final currency = product['currency']?.toString() ?? 'SEK';
    final durationDays = product['duration_days'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: buying ? null : () { HapticFeedback.selectionClick(); onTap(); },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Name + duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (durationDays > 0)
                        Text(
                          _formatDuration(durationDays),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Price + arrow
                Text(
                  '$price $currency',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                buying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
      child: Column(
        children: List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
