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
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
        : theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Card(
      elevation: isDark ? 1 : 3,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.04 : 0.07),
      margin: margin,
      color: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor, width: isDark ? 0 : 1),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
