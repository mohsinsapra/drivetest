import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/platform_detector.dart';
import 'package:taxi_exam_app/core/utils/web_redirect.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/app_sheet.dart';

const _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.mohsinsapra.drivetest';
const _kAppStoreUrl = 'https://apps.apple.com/app/drive-test-pro/id6765940954';
const _kLandingUrl = 'https://drivetest.se/';

Future<void> showAppDownloadSheet(
  BuildContext context, {
  required WebPlatform platform,
}) async {
  assert(kIsWeb, 'showAppDownloadSheet should only be called on web');
  assert(platform != WebPlatform.none);
  if (!context.mounted) return;
  await showAppSheet<void>(
    context,
    builder: (_) => _AppDownloadSheet(platform: platform),
  );
}

class _AppDownloadSheet extends StatelessWidget {
  const _AppDownloadSheet({required this.platform});

  final WebPlatform platform;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);
    final isAndroid = platform == WebPlatform.android;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icon + title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isAndroid
                      ? Icons.android_rounded
                      : Icons.phone_iphone_rounded,
                  color: cs.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t.app_download_title,
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            isAndroid
                ? t.app_download_subtitle_android
                : t.app_download_subtitle_ios,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),

          // Primary CTA — opens store
          AppButton(
            label:
                isAndroid ? t.app_download_cta_android : t.app_download_cta_ios,
            onPressed: () => redirectToUrl(
              isAndroid ? _kPlayStoreUrl : _kAppStoreUrl,
            ),
            height: 56,
          ),
          const SizedBox(height: 12),

          // Learn more link
          Center(
            child: TextButton(
              onPressed: () => redirectToUrl(_kLandingUrl),
              child: Text(
                t.app_download_learn_more,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Dismiss
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                t.app_download_dismiss,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
