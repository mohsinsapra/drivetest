import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_licences_screen.dart';

class FreeBcdHubCard extends StatefulWidget {
  const FreeBcdHubCard({super.key});

  @override
  State<FreeBcdHubCard> createState() => _FreeBcdHubCardState();
}

class _FreeBcdHubCardState extends State<FreeBcdHubCard> {
  Map<String, dynamic>? _category;

  @override
  void initState() {
    super.initState();
    _resolveCategory();
  }

  Future<void> _resolveCategory() async {
    await BcdCache.instance.ensureLoaded();
    if (!mounted) return;
    final match = _findFreeCategory();
    if (match != null) setState(() => _category = match);
  }

  Map<String, dynamic>? _findFreeCategory() {
    final cats = BcdCache.instance.categories;
    if (cats.isEmpty) return null;

    final match = cats.firstWhereOrNull(
          (c) =>
              (c['name']?.toString() ?? '').toLowerCase().contains('vägmärk'),
        ) ??
        cats.firstWhereOrNull((c) => c['subscription_product'] == null) ??
        cats.first;
    return Map<String, dynamic>.from(match);
  }

  void _handleTap() {
    final cat = _category;
    if (cat == null) {
      Navigator.push(
        context,
        AppPageRoute(builder: (_) => const BCDLicencesScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    final catName = _category?['name']?.toString();
    final displayTitle = catName ?? t.dash_free_hub_title;
    final accent =
        catName != null ? categoryColor(catName) : const Color(0xFF4F46E5);
    final icon =
        catName != null ? categoryIcon(catName) : Icons.menu_book_rounded;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _handleTap,
        splashColor: cs.primary.withValues(alpha: 0.08),
        highlightColor: cs.primary.withValues(alpha: 0.05),
        hoverColor: cs.primary.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.dash_free_hub_badge,
                            style: GoogleFonts.lexend(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.dash_free_hub_subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          t.free_trial_banner_cta,
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: cs.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
