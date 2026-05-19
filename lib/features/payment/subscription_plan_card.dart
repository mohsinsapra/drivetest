import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.product,
    required this.featured,
    required this.onPressed,
    this.purchasing = false,
    this.owned = false,
    this.ctaLabel,
    this.badgeLabel,
    this.showIcon = false,
  });

  final Map<String, dynamic> product;
  final bool featured;
  final bool purchasing;
  final bool owned;
  final VoidCallback? onPressed;
  final String? ctaLabel;
  final String? badgeLabel;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = product['name']?.toString().trim().isNotEmpty == true
        ? product['name'].toString()
        : t.onb_no_plan_selected;
    final price = formatSubscriptionProductPrice(product, context);
    final duration = formatSubscriptionProductDuration(product, context);
    final buttonLabel = ctaLabel ??
        (owned
            ? t.bcd_start_practice
            : featured
                ? t.onb_get_best_deal
                : t.onb_choose_plan);
    final icon = showIcon ? categoryIcon(title) : null;
    final iconColor = showIcon ? categoryColor(title) : null;

    if (featured) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.inverseSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cs.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badgeLabel != null) ...[
                  _PlanBadge(
                    label: badgeLabel!,
                    backgroundColor: cs.secondaryContainer,
                    textColor: cs.onSecondaryContainer,
                  ),
                  const SizedBox(height: 12),
                ] else
                  const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      _PlanIconBadge(icon: icon, color: iconColor!, dark: true),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onInverseSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: GoogleFonts.lexend(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: cs.inversePrimary,
                    height: 1,
                  ),
                ),
                if (duration != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      duration,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.secondaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _PlanFeatureRow(
                  label: t.onb_feature_mock_exams,
                  color: cs.secondaryContainer,
                  textColor: cs.onInverseSurface.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 10),
                _PlanFeatureRow(
                  label: t.onb_feature_progress_tracking,
                  color: cs.secondaryContainer,
                  textColor: cs.onInverseSurface.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 10),
                _PlanFeatureRow(
                  label: t.onb_feature_explanations,
                  color: cs.secondaryContainer,
                  textColor: cs.onInverseSurface.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 24),
                _PlanButton(
                  featured: true,
                  purchasing: purchasing,
                  owned: owned,
                  onPressed: onPressed,
                  label: buttonLabel,
                ),
              ],
            ),
          ),
          if (badgeLabel == null)
            Positioned(
              top: -14,
              left: 0,
              right: 0,
              child: Center(
                child: _PlanBadge(
                  label: t.onb_best_value,
                  backgroundColor: cs.secondaryContainer,
                  textColor: cs.onSecondaryContainer,
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.surfaceContainerHighest, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeLabel != null) ...[
            _PlanBadge(
              label: badgeLabel!,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              textColor: cs.primary,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                _PlanIconBadge(icon: icon, color: iconColor!, dark: false),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: GoogleFonts.lexend(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              height: 1,
            ),
          ),
          if (duration != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                duration,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.outline,
                ),
              ),
            ),
          const SizedBox(height: 20),
          _PlanFeatureRow(
            label: t.onb_feature_mock_exams,
            color: cs.primary,
            textColor: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          _PlanFeatureRow(
            label: t.onb_feature_progress_tracking,
            color: cs.primary,
            textColor: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 20),
          _PlanButton(
            featured: false,
            purchasing: purchasing,
            owned: owned,
            onPressed: onPressed,
            label: buttonLabel,
          ),
        ],
      ),
    );
  }
}

class SubscriptionLegalLinks extends StatelessWidget {
  const SubscriptionLegalLinks({super.key, this.colorScheme});

  final ColorScheme? colorScheme;

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = colorScheme ?? Theme.of(context).colorScheme;
    final color = cs.onSurface.withValues(alpha: 0.4);
    final style = TextStyle(
      fontSize: 11,
      color: color,
      decoration: TextDecoration.underline,
    );
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          GestureDetector(
            onTap: () => _open(
              'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
            ),
            child: Text(t.legal_terms_of_use, style: style),
          ),
          Text('·', style: TextStyle(fontSize: 11, color: color)),
          GestureDetector(
            onTap: () => _open('https://drivetest.se/privacy-policy.html'),
            child: Text(t.legal_privacy_policy, style: style),
          ),
        ],
      ),
    );
  }
}

class _PlanButton extends StatelessWidget {
  const _PlanButton({
    required this.featured,
    required this.purchasing,
    required this.owned,
    required this.onPressed,
    required this.label,
  });

  final bool featured;
  final bool purchasing;
  final bool owned;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = purchasing
        ? SizedBox(
            width: featured ? 20 : 18,
            height: featured ? 20 : 18,
            child: AppLoadingIndicator(
              strokeWidth: featured ? 2.5 : 2,
              color: featured || owned ? Colors.white : cs.primary,
            ),
          )
        : Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: featured ? 16 : 15,
              fontWeight: FontWeight.w700,
            ),
          );

    if (featured || owned) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: purchasing ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: owned ? const Color(0xFF059669) : cs.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: cs.primary.withValues(alpha: 0.3),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: purchasing ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.primary, width: 2),
          shape: const StadiumBorder(),
          foregroundColor: cs.primary,
        ),
        child: child,
      ),
    );
  }
}

class _PlanFeatureRow extends StatelessWidget {
  const _PlanFeatureRow({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanIconBadge extends StatelessWidget {
  const _PlanIconBadge({
    required this.icon,
    required this.color,
    required this.dark,
  });

  final IconData icon;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg =
        dark ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.10);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: textColor,
        ),
      ),
    );
  }
}

String formatSubscriptionProductPrice(
  Map<String, dynamic> product,
  BuildContext context,
) {
  final price = product['price']?.toString().trim() ?? '';
  final currency = product['currency']?.toString().trim() ?? '';
  if (price.isEmpty && currency.isEmpty) {
    return Translations.of(context).onb_price_unavailable;
  }
  if (price.isEmpty) return currency;
  if (currency.isEmpty) return price;
  return '$price $currency';
}

String? formatSubscriptionProductDuration(
  Map<String, dynamic> product,
  BuildContext context,
) {
  final rawDuration = product['duration_days'];
  final days = rawDuration is num
      ? rawDuration.toInt()
      : int.tryParse('${rawDuration ?? ''}');
  if (days == null || days <= 0) return null;
  final t = Translations.of(context);
  if (days >= 365) {
    return t.onb_duration_year_access
        .replaceAll('{n}', '${(days / 365).round()}');
  }
  if (days >= 30) {
    return t.onb_duration_months_access
        .replaceAll('{n}', '${(days / 30).round()}');
  }
  if (days == 1) return t.onb_duration_one_day;
  return t.onb_duration_days.replaceAll('{n}', '$days');
}

bool isFeaturedSubscriptionProduct(Map<String, dynamic> product) {
  return product['is_best_value'] == true ||
      product['is_recommended'] == true ||
      product['featured'] == true;
}
