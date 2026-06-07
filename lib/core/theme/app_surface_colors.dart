import 'package:flutter/material.dart';

@immutable
class AppSurfaceColors {
  const AppSurfaceColors({
    required this.page,
    required this.card,
    required this.sectionLabel,
    required this.divider,
  });

  final Color page;
  final Color card;
  final Color sectionLabel;
  final Color divider;

  factory AppSurfaceColors.fromTheme(ThemeData theme) {
    return AppSurfaceColors(
      page: theme.scaffoldBackgroundColor,
      card: theme.cardColor,
      sectionLabel: theme.colorScheme.onSurfaceVariant,
      divider: theme.dividerColor,
    );
  }
}
