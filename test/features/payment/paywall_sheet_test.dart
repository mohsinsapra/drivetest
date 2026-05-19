import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/features/payment/paywall_sheet.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .single;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets(
    'paywall sheet uses onboarding-style subscription card CTAs and legal links',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 3200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showPaywallSheet(
                      context,
                      products: const [
                        {
                          'id': 1,
                          'name': '30 Days',
                          'price': '199',
                          'currency': 'SEK',
                          'duration_days': 30,
                          'is_active': true,
                        },
                        {
                          'id': 2,
                          'name': '90 Days',
                          'price': '499',
                          'currency': 'SEK',
                          'duration_days': 90,
                          'is_active': true,
                        },
                      ],
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Get Best Deal'), findsNothing);
      expect(find.text('Continue'), findsNWidgets(2));
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Full mock exam library'), findsWidgets);
    },
  );

  testWidgets('paywall sheet returns the tapped product', (tester) async {
    Map<String, dynamic>? selected;

    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    selected = await showPaywallSheet(
                      context,
                      products: const [
                        {
                          'id': 1,
                          'name': '30 Days',
                          'price': '199',
                          'currency': 'SEK',
                          'duration_days': 30,
                          'is_active': true,
                        },
                        {
                          'id': 2,
                          'name': '90 Days',
                          'price': '499',
                          'currency': 'SEK',
                          'duration_days': 90,
                          'is_active': true,
                        },
                      ],
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue').last);
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!['id'], 2);
  });
}
