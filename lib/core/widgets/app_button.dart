import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
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
              colors: [
                cs.primary.withValues(alpha: 0.82),
                cs.primaryContainer.withValues(alpha: 0.88),
              ],
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
                    child: AppLoadingIndicator(
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
                    child:
                        AppLoadingIndicator(strokeWidth: 2, color: cs.primary),
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

// ── AppFilledButton ───────────────────────────────────────────────────────────
// Solid-colour filled button — replaces FilledButton / ElevatedButton with an
// explicit primary background in cards and sheets.
// Defaults to cs.primary (0.9 alpha), cs.onPrimary, borderRadius 12.

class AppFilledButton extends StatelessWidget {
  const AppFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 9999,
    this.padding = const EdgeInsets.symmetric(vertical: 13),
    this.minimumWidth = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double minimumWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.primary.withValues(alpha: 0.78);
    final fg = foregroundColor ?? cs.onPrimary;
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius));
    final style = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      padding: padding,
      minimumSize: Size(minimumWidth, 0),
      shape: shape,
    );
    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: AppLoadingIndicator(strokeWidth: 2, color: fg))
        : Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: fg));

    if (icon != null && !loading) {
      return ElevatedButton.icon(
          onPressed: onPressed, icon: icon!, label: Text(label), style: style);
    }
    return ElevatedButton(onPressed: onPressed, style: style, child: child);
  }
}

// ── AppOutlinedButton ─────────────────────────────────────────────────────────
// Outlined button — replaces OutlinedButton / OutlinedButton.icon.

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius = 9999,
    this.padding,
    this.minimumWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? minimumWidth;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius));
    final style = OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      side: borderColor != null ? BorderSide(color: borderColor!) : null,
      padding: padding,
      minimumSize: minimumWidth != null ? Size(minimumWidth!, 0) : null,
      shape: shape,
    );
    if (icon != null) {
      return OutlinedButton.icon(
          onPressed: onPressed, icon: icon!, label: Text(label), style: style);
    }
    return OutlinedButton(
        onPressed: onPressed, style: style, child: Text(label));
  }
}

// ── AppDangerButton ───────────────────────────────────────────────────────────
// Destructive filled button — red background, white text.
// Use for logout, delete, and irreversible actions.

class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 50,
    this.borderRadius = 9999,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, height),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius)),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: AppLoadingIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ── AppTextButton ─────────────────────────────────────────────────────────────
// Text-only button — replaces TextButton / TextButton.icon used as CTA,
// cancel, or secondary actions (not TextField suffixIcon).

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.foregroundColor,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? foregroundColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: foregroundColor,
      textStyle: fontSize != null ? TextStyle(fontSize: fontSize) : null,
    );
    if (icon != null) {
      return TextButton.icon(
          onPressed: onPressed, icon: icon!, label: Text(label), style: style);
    }
    return TextButton(onPressed: onPressed, style: style, child: Text(label));
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
    this.iconColor,
  });

  final FaIconData icon;
  final double iconSize;
  final VoidCallback? onPressed;
  final String? label;
  final bool loading;
  final String? loadingLabel;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? cs.primary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9999),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(9999),
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
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: AppLoadingIndicator(
                              strokeWidth: 2, color: cs.primary),
                        )
                      : FaIcon(icon, size: iconSize, color: effectiveIconColor),
                  if (loading && loadingLabel != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      loadingLabel!,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
