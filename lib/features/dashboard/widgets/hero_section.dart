import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/glass_box.dart';
import 'package:taxi_exam_app/features/notifications/notifications_screen.dart';
import '../models/dashboard_stats.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, this.stats});

  final ExamDashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);
    final progress = stats?.overallProgressPercent ?? 0;

    final String subtitle;
    if (progress == 0) {
      subtitle = t.dash_hero_sub_start;
    } else if (progress < 50) {
      subtitle = t.dash_hero_sub_progress;
    } else if (progress < 100) {
      subtitle = t.dash_hero_sub_almost;
    } else {
      subtitle = t.dash_hero_sub_done;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.dash_my_progress,
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.1,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Consumer<NotificationProvider>(
            builder: (_, notifProvider, __) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                AppPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: GlassBox(
                borderRadius: BorderRadius.circular(24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 22, color: cs.onSurface.withValues(alpha: 0.75)),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: cs.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
