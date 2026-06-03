import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/features/dashboard/models/exam_node.dart';
import 'package:taxi_exam_app/features/dashboard/models/subscribed_exam.dart';
import 'package:taxi_exam_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:taxi_exam_app/features/dashboard/repository/dashboard_repository.dart';
import 'package:taxi_exam_app/features/dashboard/repository/exam_sync_service.dart';

class _FakeDashboardRepository implements DashboardRepository {
  List<SubscribedExam> _items = [];

  @override
  Future<List<SubscribedExam>> loadSubscribedExams() async => List.of(_items);

  @override
  Future<void> removeSubscribedExam(String examId) async {
    _items.removeWhere((e) => e.id == examId);
  }

  @override
  Future<void> saveAll(List<SubscribedExam> exams) async {
    _items = List.of(exams);
  }

  @override
  Future<void> saveSubscribedExam(SubscribedExam exam) async {
    _items.removeWhere((e) => e.id == exam.id);
    _items.add(exam);
  }
}

class _FakeExamSyncService extends ExamSyncService {
  _FakeExamSyncService(this.exams);

  final List<SubscribedExam> exams;

  @override
  Future<List<SubscribedExam>> fetchSubscribedExams() async => exams;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dashboard_provider_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TestAttemptAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SubscribedExamAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ExamNodeAdapter());
    }
    await DioClient().init();
    AppStorage.setCurrentUser('test-user');

    final attemptsBox = await AppStorage.testAttemptsBox();
    await attemptsBox.put(
      'attempt-1',
      TestAttempt(
        testId: 'attempt-1',
        dateTime: DateTime(2026, 5, 21),
        userSelections: const {},
        score: 80,
        hasPassed: true,
        questions: const [],
        licenceName: 'Licence',
        categoryName: 'Batch 1',
        status: 'completed',
        licenceId: 'licence',
        categoryId: 'batch-1',
      ),
    );
  });

  tearDown(() async {
    AppStorage.clearCurrentUser();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('init notifies only loading and settled loaded states', () async {
    final exam = SubscribedExam(
      id: 'exam-1',
      name: 'Exam 1',
      hasCategories: false,
      subscribedAt: DateTime(2026, 5, 21),
      isBcd: true,
      nodes: const [
        ExamNode(
          id: 'batch-1',
          name: 'Batch 1',
          nodeTypeIndex: 1,
          sortOrder: 0,
        ),
      ],
    );

    final provider = DashboardProvider(
      repository: _FakeDashboardRepository(),
      syncService: _FakeExamSyncService([exam]),
    );

    var notifications = 0;
    provider.addListener(() {
      notifications++;
    });

    await provider.init();

    for (var i = 0; i < 20 && provider.status == DashboardStatus.loading; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(provider.status, DashboardStatus.loaded);
    expect(provider.selectedExam?.id, exam.id);
    expect(notifications, 2);
  });

  test('selectExam keeps previous stats visible during lightweight switch', () async {
    final exam1 = SubscribedExam(
      id: 'exam-1',
      name: 'Exam 1',
      hasCategories: false,
      subscribedAt: DateTime(2026, 5, 21),
      isBcd: true,
      nodes: const [
        ExamNode(
          id: 'batch-1',
          name: 'Batch 1',
          nodeTypeIndex: 1,
          sortOrder: 0,
        ),
      ],
    );
    final exam2 = SubscribedExam(
      id: 'exam-2',
      name: 'Exam 2',
      hasCategories: false,
      subscribedAt: DateTime(2026, 5, 22),
      isBcd: true,
      nodes: const [
        ExamNode(
          id: 'batch-2',
          name: 'Batch 2',
          nodeTypeIndex: 1,
          sortOrder: 0,
        ),
      ],
    );

    final provider = DashboardProvider(
      repository: _FakeDashboardRepository(),
      syncService: _FakeExamSyncService([exam1, exam2]),
    );

    await provider.init();

    for (var i = 0; i < 20 && provider.status == DashboardStatus.loading; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(provider.selectedExam?.id, exam1.id);
    expect(provider.selectedStats?.exam.id, exam1.id);

    provider.selectExam(exam2);

    expect(provider.selectedExam?.id, exam2.id);
    expect(provider.selectedStats?.exam.id, exam1.id);
    expect(provider.switching, true);

    await Future<void>.delayed(const Duration(milliseconds: 220));

    expect(provider.selectedStats?.exam.id, exam2.id);
    expect(provider.switching, false);
  });
}
