import 'package:taxi_exam_app/core/models/test_attempt.dart';

class TestAttemptSaveResult {
  const TestAttemptSaveResult({
    required this.localSaved,
    required this.backendSynced,
  });

  final bool localSaved;
  final bool backendSynced;

  bool get fullySynced => localSaved && backendSynced;
}

class TestAttemptSaveService {
  const TestAttemptSaveService({
    required this.saveLocal,
    required this.syncRemote,
  });

  final Future<void> Function(TestAttempt attempt) saveLocal;
  final Future<bool> Function(TestAttempt attempt) syncRemote;

  Future<TestAttemptSaveResult> save(TestAttempt attempt) async {
    await saveLocal(attempt);
    final backendSynced = await syncRemote(attempt);
    return TestAttemptSaveResult(
      localSaved: true,
      backendSynced: backendSynced,
    );
  }
}
