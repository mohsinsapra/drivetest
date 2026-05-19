import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/features/bcd/bcd_text_utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
            const Icon(LucideIcons.lock, size: 40, color: Color(0xFF4F46E5)),
            const SizedBox(height: 12),
            Text(
              title ?? t.bcd_subscription_required,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
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
                    children: active
                        .map((p) => _PlanTile(
                              product: p,
                              onTap: () => Navigator.pop(context, p),
                            ))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            AppTextButton(
              label: t.bcd_not_now,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 4),
            _LegalLinks(),
          ],
        ),
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    final style = TextStyle(fontSize: 11, color: color, decoration: TextDecoration.underline);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _open('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
          child: Text(t.legal_terms_of_use, style: style),
        ),
        Text('  ·  ', style: TextStyle(fontSize: 11, color: color)),
        GestureDetector(
          onTap: () => _open('https://drivetest.se/privacy-policy.html'),
          child: Text(t.legal_privacy_policy, style: style),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.product, required this.onTap});
  final dynamic product;
  final VoidCallback onTap;

  String _fmt(int days) {
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
    final days = (product['duration_days'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border:
            Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanBcdText(name),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (days > 0)
                        Text(
                          _fmt(days),
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Text(
                  '$price $currency',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
