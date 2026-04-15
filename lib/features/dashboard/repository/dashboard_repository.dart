import '../models/subscribed_exam.dart';

/// Abstract repository for subscribed-exam persistence.
/// Swap the implementation for different storage backends.
abstract class DashboardRepository {
  /// All exams the user is subscribed to.
  Future<List<SubscribedExam>> loadSubscribedExams();

  /// Persist (add or replace) a subscribed exam.
  Future<void> saveSubscribedExam(SubscribedExam exam);

  /// Remove by id.
  Future<void> removeSubscribedExam(String examId);

  /// Replace the entire list (used for initial seeding or remote sync).
  Future<void> saveAll(List<SubscribedExam> exams);
}
