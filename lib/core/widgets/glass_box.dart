import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Frosted-glass container on iOS; plain white container everywhere else.
///
/// On iOS wraps [child] in a [BackdropFilter] blur so content scrolling
/// behind shows through. On Android/web renders a solid white surface with
/// the same shape and shadow — no performance cost.
class GlassBox extends StatelessWidget {
  const GlassBox({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(50)),
    this.padding,
    this.boxShadow,
    this.border,
    this.blurSigma = 20.0,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  /// Border shown on non-iOS platforms (e.g. subtle gray outline on Android).
  final BoxBorder? border;

  /// Blur intensity on iOS. Default 20 matches iOS system sheets.
  final double blurSigma;

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isIOS && !isDark) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 0.5,
              ),
              boxShadow: boxShadow,
            ),
            child: child,
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
