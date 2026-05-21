import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/dashboard/models/dashboard_stats.dart';
import 'package:taxi_exam_app/features/dashboard/models/subscribed_exam.dart';
import 'package:taxi_exam_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:taxi_exam_app/features/dashboard/widgets/dashboard_body.dart';
import 'package:taxi_exam_app/features/dashboard/widgets/performance_insight_card.dart';
import 'package:taxi_exam_app/features/dashboard/widgets/performance_metric_card.dart';
import 'package:taxi_exam_app/features/dashboard/widgets/performance_overview_section.dart';

class _LoadingDashboardProvider extends ChangeNotifier
    implements DashboardProvider {
  @override
  DashboardStatus get status => DashboardStatus.loading;

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
  bool get switching => false;

  @override
  String? get error => null;

  @override
  DashboardErrorKind get errorKind => DashboardErrorKind.unknown;

  @override
  Future<void> init() async {}

  @override
  void refresh() {}

  @override
  Future<void> syncNow() async {}

  @override
  void selectExam(SubscribedExam exam) {}

  @override
  void reset() {}

  @override
  PeriodFilter get period => PeriodFilter.thisMonth;

  @override
  Future<void> setPeriod(PeriodFilter p) async {}

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

  @override
  Future<void> clearAll() async {}
}

void main() {
  testWidgets(
    'full-screen dashboard loading uses the real performance section layout',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DashboardProvider>(
              create: (_) => _LoadingDashboardProvider(),
            ),
            ChangeNotifierProvider<NotificationProvider>(
              create: (_) => _MockNotificationProvider(),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: Scaffold(
                body: DashboardBody(
                  provider: _LoadingDashboardProvider(),
                  onSubscribe: () {},
                  onRefresh: () async {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(PerformanceOverviewSection), findsOneWidget);
      expect(find.byType(PerformanceMetricCard), findsNWidgets(3));
      expect(find.byType(PerformanceInsightCard), findsOneWidget);
    },
  );
}
