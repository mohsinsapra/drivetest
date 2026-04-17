import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/features/dashboard/models/dashboard_stats.dart';
import 'package:taxi_exam_app/features/dashboard/models/subscribed_exam.dart';
import 'package:taxi_exam_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:taxi_exam_app/features/dashboard/repository/dashboard_repository.dart';
import 'package:taxi_exam_app/features/dashboard/repository/exam_sync_service.dart';
import 'package:taxi_exam_app/features/onboarding/onboarding_screen.dart';
import 'package:taxi_exam_app/features/payment/subscription_success_overlay.dart';
import 'package:taxi_exam_app/main_screen.dart';
import 'package:toastification/toastification.dart';

class _MockDashboardProvider extends ChangeNotifier implements DashboardProvider {
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
  bool get syncing => false;
  @override
  String? get error => null;
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
  @override
  void clearSelectedExam() {}
  @override
  Future<void> deleteExam(String examId) async {}
  @override
  double getProgress(String examId) => 0.0;
}

class _MockNotificationProvider extends ChangeNotifier implements NotificationProvider {
  @override
  List<LocalNotification> get notifications => [];
  @override
  int get unreadCount => 0;
  @override
  String get topNotificationType => 'general';
  @override
  Future<void> add(String title, String body, {String type = 'general'}) async {}
  @override
  Future<void> markAllRead() async {}
  @override
  Future<void> markRead(LocalNotification n) async {}
  @override
  bool hasType(String type) => false;
  @override
  Future<void> removeByType(String type) async {}
  @override
  Future<void> markAllAsRead() async {}
  @override
  Future<void> delete(int index) async {}
  @override
  Future<void> clearAll() async {}
}

class _MockRepo implements DashboardRepository {
  @override
  Future<List<SubscribedExam>> loadSubscribedExams() async => [];
  @override
  Future<void> saveSubscribedExam(SubscribedExam exam) async {}
  @override
  Future<void> removeSubscribedExam(String examId) async {}
  @override
  Future<void> saveAll(List<SubscribedExam> exams) async {}
}

class _MockSync implements ExamSyncService {
  @override
  Future<List<SubscribedExam>> syncFromRemote() async => [];
  @override
  Future<List<SubscribedExam>> fetchSubscribedExams() async => [];
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DioClient().init();
  });

  Future<void> _tapSubscribeAndWait(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Subscribe'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  Future<void> _reachSelectedPlanStep(WidgetTester tester) async {
    await tester.tap(find.text('30 Days'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 week'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
  }

  Future<SharedPreferences> _prefs(WidgetTester tester) async {
    return (await tester.runAsync(SharedPreferences.getInstance))!;
  }

  testWidgets(
    'continue stays disabled until a subscription product is selected',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(create: (_) => _MockNotificationProvider()),
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

      await tester.pumpAndSettle();

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

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(create: (_) => _MockNotificationProvider()),
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
                showAuthSheet: (_) async {
                  authSheetShown = true;
                  return true;
                },
           
                showSuccessOverlay: (_, __) async => null,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _reachSelectedPlanStep(tester);

      await _tapSubscribeAndWait(tester);

      expect(authSheetShown, isTrue);
      expect(paidProduct, isNotNull);
      expect(paidProduct?['id'], 7);
    },
  );

  testWidgets(
    'purchase stops when auth is dismissed',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      var authSheetShown = false;
      var paymentCalls = 0;
      var successOverlayCalls = 0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(create: (_) => _MockNotificationProvider()),
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
                showAuthSheet: (_) async {
                  authSheetShown = true;
                  return false;
                },
                processPayment: (_, __) async {
                  paymentCalls++;
                },
                showSuccessOverlay: (_, __) async {
                  successOverlayCalls++;
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _reachSelectedPlanStep(tester);

      await _tapSubscribeAndWait(tester);

      expect(authSheetShown, isTrue);
      expect(paymentCalls, 0);
      expect(successOverlayCalls, 0);
    },
  );

  testWidgets(
    'failed payment does not mark onboarding complete or show success overlay',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      var successOverlayCalls = 0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(create: (_) => _MockNotificationProvider()),
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
                  showSuccessOverlay: (_, __) async => null,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _reachSelectedPlanStep(tester);

      await _tapSubscribeAndWait(tester);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      final prefs = await _prefs(tester);
      expect(prefs.getBool('onboarding_complete'), isNot(isTrue));
      expect(successOverlayCalls, 0);
    },
  );

  testWidgets(
    'subscribe is disabled and payment is not re-entered while purchase is in flight',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      final paymentCompleter = Completer<void>();
      var paymentCalls = 0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(create: (_) => _MockNotificationProvider()),
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
                isLoggedIn: () => true,
                processPayment: (_, __) async {
                  paymentCalls++;
                  await paymentCompleter.future;
                },
                showSuccessOverlay: (_, __) async => null,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _reachSelectedPlanStep(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Subscribe'));
      await tester.pump();

      final subscribeButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Subscribe'),
      );
      expect(subscribeButton.onPressed, isNull);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Subscribe'));
      await tester.pump();

      expect(paymentCalls, 1);

      paymentCompleter.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'overlay failure after successful payment still marks onboarding complete',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      SharedPreferences.setMockInitialValues({});

      var paymentCalls = 0;
      var successOverlayCalls = 0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(create: (_) => _MockNotificationProvider()),
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
                    paymentCalls++;
                  },
                  showSuccessOverlay: (_, __) async {
                    successOverlayCalls++;
                    throw Exception('overlay failed');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _reachSelectedPlanStep(tester);

      await _tapSubscribeAndWait(tester);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      final prefs = await _prefs(tester);
      expect(paymentCalls, 1);
      expect(successOverlayCalls, 1);
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

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(create: (_) => _MockNotificationProvider()),
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
                showAuthSheet: (_) async {
                  authSheetShown = true;
                  return true;
                },
              
                showSuccessOverlay: (_, __) async => null,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('90 Days'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 week'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      await _tapSubscribeAndWait(tester);

      expect(authSheetShown, isFalse);
      expect(paidProduct, isNotNull);
      expect(paidProduct?['id'], 21);
    },
  );

  testWidgets(
    'selected product appears on the final onboarding step',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _MockDashboardProvider()),
            ChangeNotifierProvider<NotificationProvider>(create: (_) => _MockNotificationProvider()),
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

      await tester.pumpAndSettle();
      await tester.tap(find.text('90 Days'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 week'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('90 Days'), findsWidgets);
      expect(find.text('399 SEK'), findsOneWidget);
    },
  );
}
