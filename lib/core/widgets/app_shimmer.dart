import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// App-wide shimmer wrapper with consistent neutral light/dark colors.
/// Wrap any skeleton child in this instead of calling Shimmer.fromColors directly.
class AppShimmer extends StatelessWidget {
  static const _lightBaseColor = Color(0xFFECECEC);
  static const _lightHighlightColor = Color(0xFFFAFAFA);
  static const _darkBaseColor = Color(0xFF2E2E2E);
  static const _darkHighlightColor = Color(0xFF484848);

  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? _darkBaseColor : _lightBaseColor,
      highlightColor: isDark ? _darkHighlightColor : _lightHighlightColor,
      child: child,
    );
  }
}
