import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/theme/app_surface_colors.dart';

void main() {
  test('derives page and card surfaces from the active theme', () {
    final theme = ThemeData(
      scaffoldBackgroundColor: const Color(0xFF102030),
      cardColor: const Color(0xFF405060),
      dividerColor: const Color(0xFF708090),
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFF8F5FF),
        onSurfaceVariant: Color(0xFF556677),
      ),
    );

    final colors = AppSurfaceColors.fromTheme(theme);

    expect(colors.page, theme.scaffoldBackgroundColor);
    expect(colors.card, theme.cardColor);
    expect(colors.sectionLabel, theme.colorScheme.onSurfaceVariant);
    expect(colors.divider, theme.dividerColor);
  });
}
