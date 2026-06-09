import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';

// ── showAppConfirmDialog ───────────────────────────────────────────────────────
// Cancel (text) + Confirm (filled). Returns true if confirmed.

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  String? cancelLabel,
  bool barrierDismissible = true,
}) async {
  final t = Translations.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        AppTextButton(
          label: cancelLabel ?? t.cancel,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        AppFilledButton(
          label: confirmLabel,
          minimumWidth: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ── showAppDangerDialog ────────────────────────────────────────────────────────
// Cancel (text) + Destructive action (red). Returns true if confirmed.

Future<bool> showAppDangerDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String dangerLabel,
  String? cancelLabel,
  bool barrierDismissible = true,
}) async {
  final t = Translations.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        AppTextButton(
          label: cancelLabel ?? t.cancel,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        AppDangerButton(
          label: dangerLabel,
          borderRadius: 12,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ── showAppInfoDialog ──────────────────────────────────────────────────────────
// Centred icon + title + body + single CTA button.

Future<void> showAppInfoDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String body,
  required String ctaLabel,
  VoidCallback? onCta,
}) {
  final cs = Theme.of(context).colorScheme;
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: cs.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            AppFilledButton(
              label: ctaLabel,
              onPressed: () {
                Navigator.of(ctx).pop();
                onCta?.call();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

// ── showAppDangerSheet ─────────────────────────────────────────────────────────
// Bottom sheet: drag handle + title + body + Cancel (outlined) + Danger button.

Future<void> showAppDangerSheet({
  required BuildContext context,
  required String title,
  required String body,
  required String dangerLabel,
  required VoidCallback onConfirm,
  String? cancelLabel,
}) {
  final t = Translations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  label: cancelLabel ?? t.cancel,
                  borderRadius: 12,
                  minimumWidth: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppDangerButton(
                  label: dangerLabel,
                  borderRadius: 12,
                  height: 48,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onConfirm();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ── showAppLoadingDialog / hideAppLoadingDialog ────────────────────────────────
// Full-screen spinner overlay. Call hide with the same context to dismiss.

void showAppLoadingDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: AppLoadingIndicator()),
  );
}

void hideAppLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}
