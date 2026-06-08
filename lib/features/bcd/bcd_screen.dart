import 'package:taxi_exam_app/core/constants/app_text_styles.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'bcd_licences_screen.dart';
import 'bcd_traffic_signs_screen.dart';
import 'bcd_subscriptions_screen.dart';

class BCDScreen extends StatelessWidget {
  const BCDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final sections = [
      _Section(
        icon: LucideIcons.bookOpenCheck,
        color: const Color(0xFF4F46E5),
        title: t.bcd_exams,
        subtitle: t.bcd_exams_sub,
        onTap: () => Navigator.push(
          context,
          AppPageRoute(builder: (_) => const BCDLicencesScreen()),
        ),
      ),
      _Section(
        icon: LucideIcons.alertTriangle,
        color: const Color(0xFFD97706),
        title: t.bcd_traffic_signs,
        subtitle: t.bcd_traffic_signs_sub,
        onTap: () => Navigator.push(
          context,
          AppPageRoute(builder: (_) => const BCDTrafficSignsScreen()),
        ),
      ),
      _Section(
        icon: LucideIcons.creditCard,
        color: const Color(0xFF059669),
        title: t.bcd_subscriptions,
        subtitle: t.bcd_subscriptions_sub,
        onTap: () => Navigator.push(
          context,
          AppPageRoute(builder: (_) => const BCDSubscriptionsScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.bcd_drive_test)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _SectionCard(section: sections[i]),
      ),
    );
  }
}

class _Section {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _SectionCard extends StatelessWidget {
  final _Section section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: section.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: section.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(section.icon, color: section.color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: AppTextStyles.headingMedium(),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    section.subtitle,
                    style:
                        AppTextStyles.listSubtitle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
