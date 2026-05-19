import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/features/payment/subscription_plan_card.dart';

Future<dynamic> showPaywallSheet(
  BuildContext context, {
  required List<dynamic> products,
  String? title,
}) {
  return showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallSheet(products: products, title: title),
  );
}

class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key, required this.products, this.title});
  final List<dynamic> products;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final active = products.where((p) => p['is_active'] == true).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, sc) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title ?? t.bcd_subscription_required,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              t.onb_step4_subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (active.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  t.bcd_no_plans,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  controller: sc,
                  child: Column(
                    children: [
                      for (var i = 0; i < active.length; i++)
                        Builder(builder: (context) {
                          final p = Map<String, dynamic>.from(active[i] as Map);
                          return Padding(
                            padding: EdgeInsets.only(
                              top: i == 0 ? 12 : 0,
                              bottom: 14,
                            ),
                            child: SubscriptionPlanCard(
                              product: p,
                              featured: isFeaturedSubscriptionProduct(p),
                              ctaLabel: t.onb_continue,
                              onPressed: () =>
                                  Navigator.pop(context, active[i]),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            AppTextButton(
              label: t.bcd_not_now,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 4),
            const SubscriptionLegalLinks(),
          ],
        ),
      ),
    );
  }
}
