import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';

class SubscribeCtaCard extends StatelessWidget {
  const SubscribeCtaCard({super.key, required this.onSubscribe});

  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.dash_no_exams_found,
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.bcd_free_content_desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          AppFilledButton(
            label: t.bcd_buy_subscription,
            onPressed: onSubscribe,
            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
            backgroundColor: cs.primary.withValues(alpha: 0.85),
            padding: const EdgeInsets.symmetric(vertical: 14),
            borderRadius: 14,
          ),
        ],
      ),
    );
  }
}
