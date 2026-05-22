import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/subscribed_exam.dart';

class ExamCard extends StatelessWidget {
  const ExamCard({
    super.key,
    required this.exam,
    required this.isActive,
    this.endDate,
  });

  final SubscribedExam exam;
  final bool isActive;
  final String? endDate;

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

  String _displayName(String raw) =>
      raw.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();

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

    final expiry = _expiryLabel(t);
    final displayName = _displayName(exam.name);

    // Pick day or night image URL with mutual fallback.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Derive panel overlay from theme primary so all cards share the same colour.
    final panelColor = isDark
        ? Color.lerp(cs.primary, Colors.white, 0.28)!
        : Color.lerp(cs.primary, Colors.black, 0.25)!;
    // Inactive: moderate dim — desaturation filter already reduces visual weight.
    final inactivePanelColor = Color.lerp(
      panelColor,
      isDark ? Colors.black : Colors.white,
      isDark ? 0.30 : 0.35,
    )!;
    final imageUrl = isActive
        ? (isDark
            ? (exam.examPictureNight ?? exam.examPictureDay)
            : (exam.examPictureDay ?? exam.examPictureNight))
        : (isDark
            ? (exam.examPictureNightInactive ??
                exam.examPictureDayInactive ??
                exam.examPictureNight ??
                exam.examPictureDay)
            : (exam.examPictureDayInactive ??
                exam.examPictureNightInactive ??
                exam.examPictureDay ??
                exam.examPictureNight));

    if (isActive) {
      if (imageUrl != null) {
        return _ImageCard(
          imageUrl: imageUrl,
          panelColor: panelColor,
          isDark: isDark,
          isActive: true,
          badge: t.dash_card_active,
          name: displayName,
          expiry: expiry,
        );
      }

      // Gradient card (no custom image)
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  displayName,
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
                  Text(
                    expiry,
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.onPrimary.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    // Inactive card with image
    if (imageUrl != null) {
      return _ImageCard(
        imageUrl: imageUrl,
        panelColor: inactivePanelColor,
        isDark: isDark,
        isActive: false,
        badge: t.dash_card_inactive,
        name: displayName,
        expiry: expiry,
      );
    }

    // Inactive card — no image
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
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
            displayName,
            style: GoogleFonts.lexend(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (expiry != null)
            Text(
              expiry,
              style: GoogleFonts.plusJakartaSans(
                color: cs.onSurface.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.imageUrl,
    required this.panelColor,
    required this.isDark,
    required this.isActive,
    required this.badge,
    required this.name,
    this.expiry,
  });

  final String imageUrl;
  final Color panelColor;
  final bool isDark;
  final bool isActive;
  final String badge;
  final String name;
  final String? expiry;

  @override
  Widget build(BuildContext context) {
    const shape = BorderRadius.all(Radius.circular(24));
    // Dark mode overlay is light-tinted → dark background overall → white text.
    // Light mode overlay is dark-tinted → sits on bright image → dark text.
    final textColor = isDark ? Colors.white : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        return ClipRRect(
          borderRadius: shape,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: isActive
                    ? const ColorFilter.mode(
                        Colors.transparent, BlendMode.multiply)
                    : ColorFilter.mode(
                        Colors.grey.withValues(alpha: 0.35),
                        BlendMode.saturation,
                      ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 250),
                  fadeOutDuration: const Duration(milliseconds: 150),
                  placeholder: (_, __) => const SizedBox.expand(),
                  errorWidget: (_, __, ___) => const SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.1,
                      stops: const [0.0, 0.45, 1.0],
                      colors: [
                        panelColor.withValues(alpha: 0.90),
                        panelColor.withValues(alpha: 0.45),
                        panelColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                width: cardWidth * 0.58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.lexend(
                          color: Colors.white
                              .withValues(alpha: isActive ? 0.95 : 0.65),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: GoogleFonts.lexend(
                        color:
                            textColor.withValues(alpha: isActive ? 1.0 : 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (expiry != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        expiry!,
                        style: GoogleFonts.plusJakartaSans(
                          color: textColor.withValues(
                              alpha: isActive ? 0.75 : 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
