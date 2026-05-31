import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/providers/font_provider.dart';
import 'package:taxi_exam_app/core/providers/theme_provider.dart';
import 'package:taxi_exam_app/settings/settings.dart';

Widget _buildTestApp({
  required ThemeProvider themeProvider,
  required FontProvider fontProvider,
}) {
  return TranslationProvider(
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: fontProvider),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'light',
    });
    LocaleSettings.setLocaleSync(AppLocale.en);
    await DioClient().init();
  });

  testWidgets('shows explicit light, system, and dark theme options',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final themeProvider = ThemeProvider(prefs);
    final fontProvider = FontProvider(prefs);

    await tester.pumpWidget(
      _buildTestApp(
        themeProvider: themeProvider,
        fontProvider: fontProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('selecting system theme updates the provider', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final themeProvider = ThemeProvider(prefs);
    final fontProvider = FontProvider(prefs);

    await tester.pumpWidget(
      _buildTestApp(
        themeProvider: themeProvider,
        fontProvider: fontProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    expect(themeProvider.themeMode, ThemeMode.system);
  });
}
