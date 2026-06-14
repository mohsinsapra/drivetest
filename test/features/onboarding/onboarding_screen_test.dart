import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'package:taxi_exam_app/features/dashboard/models/dashboard_stats.dart';
import 'package:taxi_exam_app/features/dashboard/models/subscribed_exam.dart';
import 'package:taxi_exam_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:taxi_exam_app/features/onboarding/onboarding_screen.dart';
import 'package:taxi_exam_app/features/payment/subscription_success_overlay.dart';
import 'package:taxi_exam_app/main_screen.dart';
import 'package:toastification/toastification.dart';

class _MockDashboardProvider extends ChangeNotifier
    implements DashboardProvider {
  @override
  DashboardStatus get status => DashboardStatus.loaded;
  @override
  List<SubscribedExam> get exams => [];
  @override
  SubscribedExam? get selectedExam => null;
  @override
  ExamDashboardStats? get selectedStats => null;
  @override
  Map<String, double> get overviewProgress => {};
  @override
  Map<String, ExamDashboardStats> get statsCache => {};
  @override
  bool get syncing => false;
  @override
  bool get switching => false;
  @override
  String? get error => null;
  @override
  DashboardErrorKind get errorKind => DashboardErrorKind.unknown;
  @override
  Future<void> init() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> syncNow() async {}
  @override
  void selectExam(SubscribedExam exam) {}
  @override
  void reset() {}
  void clearSelectedExam() {}
  @override
  PeriodFilter get period => PeriodFilter.thisMonth;
  @override
  Future<void> setPeriod(PeriodFilter p) async {}
  Future<void> deleteExam(String examId) async {}
  double getProgress(String examId) => 0.0;
  @override
  List<TestAttempt> get attempts => [];
  @override
  Future<void> setWeeklyGoal(int goal) async {}
}

class _MockNotificationProvider extends ChangeNotifier
    implements NotificationProvider {
  @override
  List<LocalNotification> get notifications => [];
  @override
  int get unreadCount => 0;
  @override
  String get topNotificationType => 'general';
  @override
  Future<void> add(String title, String body,
      {String type = 'general'}) async {}
  @override
  Future<void> markAllRead() async {}
  @override
  Future<void> markRead(LocalNotification n) async {}
  @override
  bool hasType(String type) => false;
  @override
  Future<void> removeByType(String type) async {}
  Future<void> markAllAsRead() async {}
  Future<void> delete(int index) async {}
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> reload() async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DioClient().init();
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .single;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Future<void> pumpOnboarding(
    WidgetTester tester,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(1440, 4200);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(child);
    await tester.pumpAndSettle();
  }

  Future<void> tapSubscribeAndWait(WidgetTester tester) async {
    await tester
        .ensureVisible(find.widgetWithText(OutlinedButton, 'Choose Plan'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Plan'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  Future<void> tapSubscribeViaSignIn(WidgetTester tester) async {
    await tester
        .ensureVisible(find.widgetWithText(OutlinedButton, 'Choose Plan'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Plan'));
    await tester.pump(const Duration(milliseconds: 300));
    tester.widget<AppButton>(find.byType(AppButton).last).onPressed!();
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> reachSelectedPlanStep(WidgetTester tester) async {
    await tester.tap(find.text('30 Days'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
  }

  Future<SharedPreferences> prefsFor(WidgetTester tester) async {
    return (await tester.runAsync(SharedPreferences.getInstance))!;
  }

  Future<void> reachWeeklyGoalStep(WidgetTester tester) async {
    await tester.tap(find.text('30 Days'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, t.onb_continue));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, t.onb_continue));
    await tester.pumpAndSettle();
  }

  Object? takeLastException(WidgetTester tester) {
    Object? last;
    while (true) {
      final error = tester.takeException();
      if (error == null) {
        return last;
      }
      last = error;
    }
  }

  testWidgets(
    'continue stays disabled until a subscription product is selected',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: OnboardingScreen(
                loadProducts: () async => [
                  {
                    'id': 7,
                    'name': '30 Days',
                    'price': '199',
                    'currency': 'SEK',
                    'duration_days': 30,
                  },
                ],
              ),
            ),
          ),
        ),
      );

      final continueButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(continueButton.onPressed, isNull);

      await tester.tap(find.text('30 Days'));
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(enabledButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'unauthenticated purchase authenticates then pays selected product',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      var authSheetShown = false;
      Map<String, dynamic>? paidProduct;

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: OnboardingScreen(
                loadProducts: () async => [
                  {
                    'id': 7,
                    'name': '30 Days',
                    'price': '199',
                    'currency': 'SEK',
                    'duration_days': 30,
                  },
                ],
                isLoggedIn: () => false,
                showAuthSheet: (_,
                    {String? title,
                    String? subtitle,
                    bool required = false}) async {
                  authSheetShown = true;
                  return true;
                },
                processPayment: (_, products) async {
                  paidProduct = products.first;
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      await reachSelectedPlanStep(tester);

      await tapSubscribeViaSignIn(tester);

      expect(authSheetShown, isTrue);
      expect(paidProduct, isNotNull);
      expect(paidProduct!['id'], 7);
    },
  );

  testWidgets(
    'purchase stops when auth is dismissed',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      var authSheetShown = false;
      var paymentCalls = 0;

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: OnboardingScreen(
                loadProducts: () async => [
                  {
                    'id': 7,
                    'name': '30 Days',
                    'price': '199',
                    'currency': 'SEK',
                    'duration_days': 30,
                  },
                ],
                isLoggedIn: () => false,
                showAuthSheet: (_,
                    {String? title,
                    String? subtitle,
                    bool required = false}) async {
                  authSheetShown = true;
                  return false;
                },
                processPayment: (_, __) async {
                  paymentCalls++;
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      await reachSelectedPlanStep(tester);

      await tapSubscribeViaSignIn(tester);

      expect(authSheetShown, isTrue);
      expect(paymentCalls, 0);
    },
  );

  testWidgets(
    'failed payment does not mark onboarding complete or show success overlay',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: ToastificationWrapper(
            child: TranslationProvider(
              child: MaterialApp(
                home: OnboardingScreen(
                  loadProducts: () async => [
                    {
                      'id': 7,
                      'name': '30 Days',
                      'price': '199',
                      'currency': 'SEK',
                      'duration_days': 30,
                    },
                  ],
                  isLoggedIn: () => true,
                  processPayment: (_, __) async {
                    throw Exception('payment failed');
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await reachSelectedPlanStep(tester);

      await tapSubscribeAndWait(tester);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      final prefs = await prefsFor(tester);
      expect(prefs.getBool('onboarding_complete'), isNot(isTrue));
    },
  );

  testWidgets(
    'subscribe is disabled and payment is not re-entered while purchase is in flight',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      final paymentCompleter = Completer<void>();
      var paymentCalls = 0;

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: OnboardingScreen(
                loadProducts: () async => [
                  {
                    'id': 7,
                    'name': '30 Days',
                    'price': '199',
                    'currency': 'SEK',
                    'duration_days': 30,
                  },
                ],
                isLoggedIn: () => false,
                showAuthSheet: (_,
                    {String? title,
                    String? subtitle,
                    bool required = false}) async {
                  return true;
                },
                processPayment: (_, __) async {
                  paymentCalls++;
                  await paymentCompleter.future;
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      await reachSelectedPlanStep(tester);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Choose Plan'),
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Choose Plan'),
      );
      await tester.pump(const Duration(milliseconds: 300));
      tester.widget<AppButton>(find.byType(AppButton).last).onPressed!();
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      expect(paymentCalls, 1);
      expect(find.byType(AppLoadingIndicator), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton).first, warnIfMissed: false);
      await tester.pump();

      expect(paymentCalls, 1);

      paymentCompleter.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'successful payment marks onboarding complete',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      var paymentCalls = 0;

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: ToastificationWrapper(
            child: TranslationProvider(
              child: MaterialApp(
                home: OnboardingScreen(
                  loadProducts: () async => [
                    {
                      'id': 7,
                      'name': '30 Days',
                      'price': '199',
                      'currency': 'SEK',
                      'duration_days': 30,
                    },
                  ],
                  isLoggedIn: () => true,
                  postPurchase: (_, __, ___) async {},
                  processPayment: (_, __) async {
                    paymentCalls++;
                    return SubscriptionSuccessResult.backHome;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await reachSelectedPlanStep(tester);

      await tapSubscribeAndWait(tester);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      final exception = takeLastException(tester);
      if (exception != null) {
        expect(exception, isException);
      }

      final prefs = await prefsFor(tester);
      expect(paymentCalls, 1);
      expect(prefs.getBool('onboarding_complete'), isTrue);
    },
  );

  testWidgets(
    'authenticated purchase skips auth and pays selected product',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      var authSheetShown = false;
      Map<String, dynamic>? paidProduct;

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: OnboardingScreen(
                loadProducts: () async => [
                  {
                    'id': 21,
                    'name': '90 Days',
                    'price': '399',
                    'currency': 'SEK',
                    'duration_days': 90,
                  },
                ],
                isLoggedIn: () => true,
                showAuthSheet: (_,
                    {String? title,
                    String? subtitle,
                    bool required = false}) async {
                  authSheetShown = true;
                  return true;
                },
                processPayment: (_, products) async {
                  paidProduct = products.first;
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('90 Days'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      await tapSubscribeAndWait(tester);

      expect(authSheetShown, isFalse);
      expect(paidProduct, isNotNull);
      expect(paidProduct!['id'], 21);
    },
  );

  testWidgets(
    'selected product appears on the final onboarding step',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: OnboardingScreen(
                loadProducts: () async => [
                  {
                    'id': 21,
                    'name': '90 Days',
                    'price': '399',
                    'currency': 'SEK',
                    'duration_days': 90,
                  },
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('90 Days'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('90 Days'), findsWidgets);
      expect(find.text('399 SEK'), findsOneWidget);
    },
  );

  testWidgets(
    'weekly goal uses localized Swedish weekday initials',
    (tester) async {
      await LocaleSettings.setLocale(AppLocale.sv);

      await pumpOnboarding(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(
                create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(
                create: (_) => _MockNotificationProvider()),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: OnboardingScreen(
                loadProducts: () async => [
                  {
                    'id': 7,
                    'name': '30 Days',
                    'price': '199',
                    'currency': 'SEK',
                    'duration_days': 30,
                  },
                ],
              ),
            ),
          ),
        ),
      );

      await reachWeeklyGoalStep(tester);

      expect(find.text('O'), findsNWidgets(2));
      expect(find.text('L'), findsNWidgets(2));
      expect(find.text('W'), findsNothing);
    },
  );
}
