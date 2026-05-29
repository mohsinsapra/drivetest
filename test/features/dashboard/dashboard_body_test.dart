import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/dashboard/models/dashboard_stats.dart';
import 'package:taxi_exam_app/features/dashboard/models/exam_node.dart';
import 'package:taxi_exam_app/features/dashboard/models/subscribed_exam.dart';
import 'package:taxi_exam_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:taxi_exam_app/features/dashboard/widgets/category_list_item.dart';
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
  setUpAll(() async {
    await DioClient().init();
  });

  ExamDashboardStats dashboardStatsFor(CategoryStats category) {
    return ExamDashboardStats(
      exam: SubscribedExam(
        id: 'exam-1',
        name: 'Exam 1',
        hasCategories: true,
        subscribedAt: DateTime(2026, 5, 29),
        nodes: const [],
      ),
      categoryStats: [category],
      allBatchStats: category.batchStats,
      streak: const StreakSummary(
        currentStreak: 0,
        bestStreak: 0,
        thisWeekActiveDays: [],
        weeklyGoal: 3,
        thisWeekActiveDayCount: 0,
      ),
    );
  }

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

  testWidgets(
    'focus area toggle uses the checklist primary icon color',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      const category = CategoryStats(
        node: ExamNode(
          id: 'category-1',
          name: 'Vehicle Checks',
          nodeTypeIndex: 0,
        ),
        batchStats: [],
      );
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        cardColor: Colors.white,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: CategoryListItem(
                cat: category,
                icon: Icons.directions_car,
                isExpanded: false,
                onToggle: () {},
                stats: dashboardStatsFor(category),
              ),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.directions_car));

      expect(icon.color, theme.colorScheme.primary);
    },
  );
}
