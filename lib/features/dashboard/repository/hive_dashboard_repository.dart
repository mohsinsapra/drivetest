import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import '../models/subscribed_exam.dart';
import 'dashboard_repository.dart';

/// Hive-backed implementation of [DashboardRepository].
/// Works on mobile, desktop, and Flutter web (Hive uses IndexedDB on web).
class HiveDashboardRepository implements DashboardRepository {
  Future<Box<SubscribedExam>> get _box => AppStorage.subscribedExamsBox();

  @override
  Future<List<SubscribedExam>> loadSubscribedExams() async {
    final box = await _box;
    return box.values.toList();
  }

  @override
  Future<void> saveSubscribedExam(SubscribedExam exam) async {
    final box = await _box;
    await box.put(exam.id, exam);
  }

  @override
  Future<void> removeSubscribedExam(String examId) async {
    final box = await _box;
    await box.delete(examId);
  }

  @override
  Future<void> saveAll(List<SubscribedExam> exams) async {
    final box = await _box;
    await box.clear();
    final map = {for (final e in exams) e.id: e};
    await box.putAll(map);
  }
}
