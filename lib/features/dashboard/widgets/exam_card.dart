import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/subscribed_exam.dart';
import 'circular_progress_ring.dart';

class ExamCard extends StatelessWidget {
  const ExamCard({
    super.key,
    required this.exam,
    required this.progress,
    required this.isActive,
    this.endDate,
    this.onArrowTap,
  });

  final SubscribedExam exam;
  final double progress;
  final bool isActive;
  final String? endDate;
  final VoidCallback? onArrowTap;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String? _expiryLabel(Translations t) {
    final iso = endDate;
    if (iso == null || iso.isEmpty) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = dt.difference(now);
      final dateStr = '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
      if (diff.inDays < 0) {
        return t.dash_card_expired.replaceAll('{date}', dateStr);
      }
      if (diff.inDays == 0) return t.dash_card_expires_today;
      if (diff.inDays == 1) return t.dash_card_expires_tomorrow;
      if (diff.inDays <= 14) {
        return t.dash_card_expires_days.replaceAll('{days}', '${diff.inDays}');
      }
      return t.dash_card_expires_on.replaceAll('{date}', dateStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final t = Translations.of(context);

    final progressValue = progress / 100.0;
    final progressLabel = '${progress.toStringAsFixed(0)}%';
    final expiry = _expiryLabel(t);

    if (isActive) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t.dash_card_active,
                    style: GoogleFonts.lexend(
                      color: cs.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Text(
                  exam.name,
                  style: GoogleFonts.lexend(
                    color: cs.onPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (expiry != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      expiry,
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.onPrimary.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircularProgressRing(
                      value: progressValue,
                      label: progressLabel,
                      trackColor: cs.onPrimary.withValues(alpha: 0.2),
                      progressColor: cs.onPrimary,
                      textColor: cs.onPrimary,
                    ),
                    GestureDetector(
                      onTap: onArrowTap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: cs.onPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Inactive card
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.dash_card_inactive,
              style: GoogleFonts.lexend(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Text(
            exam.name,
            style: GoogleFonts.lexend(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircularProgressRing(
                value: progressValue,
                label: progressLabel,
                trackColor: cs.onSurface.withValues(alpha: 0.12),
                progressColor: cs.primary,
                textColor: cs.onSurface.withValues(alpha: 0.6),
              ),
              GestureDetector(
                onTap: onArrowTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: cs.onSurface.withValues(alpha: 0.4),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
