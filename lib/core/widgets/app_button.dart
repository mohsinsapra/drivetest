import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// ── AppButton ─────────────────────────────────────────────────────────────────
// Primary gradient pill — all main CTAs across the app.
// Full width by default; height 58 for screens, 54 for sheets.

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.icon,
    this.height = 58,
    this.fontSize = 17,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final Widget? icon;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(9999),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: cs.onPrimary, strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 10),
                ],
                Text(
                  loading ? (loadingLabel ?? label) : label,
                  style: GoogleFonts.lexend(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AppSecondaryButton ────────────────────────────────────────────────────────
// Secondary action button — subtle gradient with a light primary touch, no border.
// Use for "Continue as guest", "Cancel", and similar secondary CTAs.

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 54,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(9999),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withValues(alpha: 0.10),
                cs.primaryContainer.withValues(alpha: 0.18),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: GoogleFonts.lexend(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AppSocialButton ───────────────────────────────────────────────────────────
// Social sign-in button (Apple / Google) — icon + label in a Row, subtle
// gradient, no border.  Place inside a fixed-height Row; uses Expanded.

class AppSocialButton extends StatelessWidget {
  const AppSocialButton({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.onPressed,
    this.label,
    this.loading = false,
    this.loadingLabel,
  });

  final IconData icon;
  final double iconSize;
  final VoidCallback? onPressed;
  final String? label;
  final bool loading;

  /// Short text shown next to spinner while loading.
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.10),
                  cs.primaryContainer.withValues(alpha: 0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.primary),
                        )
                      : FaIcon(icon, size: iconSize, color: cs.primary),
                  if (loading && loadingLabel != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      loadingLabel!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (!loading && label != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      label!,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
