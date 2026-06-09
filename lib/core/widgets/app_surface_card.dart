import 'package:flutter/material.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.margin = EdgeInsets.zero,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry margin;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: borderRadius,
        border: Border.all(
            color: cs.onSurface.withValues(alpha: isDark ? 0.06 : 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
