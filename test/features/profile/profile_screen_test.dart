import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:taxi_exam_app/features/profile/profile_screen.dart';

void main() {
  setUp(() async {
    PackageInfo.setMockInitialValues(
      appName: 'Taxi Exam',
      packageName: 'com.example.taxi_exam',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({
      'user': jsonEncode({
        'username': 'Guest',
        'email': '',
        'is_guest': true,
      }),
    });
    LocaleSettings.setLocaleSync(AppLocale.en);
    NavigationService.navigatorKey = GlobalKey<NavigatorState>();
    await DioClient().init();
  });

  testWidgets('tapping guest profile header opens create account sheet',
      (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-header-row')));
    await tester.pumpAndSettle();

    expect(find.text('Save Your Progress'), findsOneWidget);
  });
}
