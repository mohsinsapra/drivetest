import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import '../helpers/dashboard_helpers.dart';
import '../models/dashboard_stats.dart';
import '../models/subscribed_exam.dart';
import '../repository/dashboard_repository.dart';
import '../repository/exam_sync_service.dart';

enum DashboardStatus { idle, loading, loaded, error }

/// ChangeNotifier provider for the exam dashboard.
///
/// Flow on [init]:
///   1. Show cached exams from Hive immediately (fast, offline-safe).
///   2. Fetch fresh structure from API in the background.
///   3. Persist the updated structure to Hive and refresh the UI.
///
/// [TestAttempt] data is read from the existing 'testAttempts' Hive box —
/// no duplication of attempt storage.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    required DashboardRepository repository,
    ExamSyncService? syncService,
  })  : _repo = repository,
        _sync = syncService ?? ExamSyncService();

  final DashboardRepository _repo;
  final ExamSyncService _sync;

  DashboardStatus _status = DashboardStatus.idle;
  DashboardStatus get status => _status;

  List<SubscribedExam> _exams = [];
  List<SubscribedExam> get exams => _exams;

  SubscribedExam? _selectedExam;
  SubscribedExam? get selectedExam => _selectedExam;

  ExamDashboardStats? _selectedStats;
  ExamDashboardStats? get selectedStats => _selectedStats;

  /// Quick overview progress % keyed by exam id.
  Map<String, double> _overviewProgress = {};
  Map<String, double> get overviewProgress => _overviewProgress;

  /// True while background API sync is running (after initial load).
  bool _syncing = false;
  bool get syncing => _syncing;

  String? _error;
  String? get error => _error;

  /// Timestamp of the last successful API sync. Used to avoid redundant calls.
  DateTime? _lastSyncedAt;

  /// Subscription to testAttempts Hive box — triggers refresh on any write.
  StreamSubscription<BoxEvent>? _attemptsSub;

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_status == DashboardStatus.loading) return;

    _status = DashboardStatus.loading;
    notifyListeners();

    try {
      // Step 1: load from Hive (instant)
      final cached = await _repo.loadSubscribedExams();
      if (cached.isNotEmpty) {
        await _applyExams(cached);
        _status = DashboardStatus.loaded;
        notifyListeners();
      }

      // Step 2: sync from API only when cache is empty or last sync is stale.
      final stale = _lastSyncedAt == null ||
          DateTime.now().difference(_lastSyncedAt!) >
              const Duration(minutes: 10);
      if (_exams.isEmpty || stale) {
        _syncFromApi();
      }

      // Step 3: subscribe to testAttempts box so any completed test
      // automatically refreshes dashboard stats — no manual pull needed.
      _subscribeToAttempts();
    } catch (e) {
      _error = e.toString();
      _status = DashboardStatus.error;
      notifyListeners();
    }
  }

  void selectExam(SubscribedExam exam) {
    // Fire-and-forget: load async then notify
    _loadAttempts().then((attempts) {
      _selectExam(exam, attempts);
      notifyListeners();
    });
  }

  /// Call after saving a [TestAttempt] so dashboard stats stay current.
  void refresh() {
    _loadAttempts().then((attempts) {
      _buildOverviewProgress(attempts);
      if (_selectedExam != null) {
        _selectedStats =
            DashboardHelpers.computeExamStats(_selectedExam!, attempts);
      }
      notifyListeners();
    });
  }

  /// Force a full re-fetch from the API (pull-to-refresh / retry).
  Future<void> syncNow() => _syncFromApi();

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<void> _syncFromApi() async {
    if (_syncing) return;
    _syncing = true;
    notifyListeners();

    try {
      final fetched = await _sync.fetchSubscribedExams();
      if (fetched.isNotEmpty) {
        await _repo.saveAll(fetched);
        final refreshed = await _repo.loadSubscribedExams();
        await _applyExams(refreshed);
        _status = DashboardStatus.loaded;
      } else if (_exams.isEmpty) {
        // API returned nothing and cache is also empty
        _status = DashboardStatus.loaded; // show empty state, not error
      }
      _lastSyncedAt = DateTime.now();
    } catch (e) {
      debugPrint('[DashboardProvider] API sync failed: $e');
      // Keep showing cached data — don't flip to error state
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Subscribes to the testAttempts Hive box. Any write (test completed or
  /// paused) triggers a stats refresh so the dashboard stays current without
  /// the user having to pull-to-refresh.
  Future<void> _subscribeToAttempts() async {
    if (_attemptsSub != null) return; // already subscribed
    try {
      final box = Hive.isBoxOpen('testAttempts')
          ? Hive.box<TestAttempt>('testAttempts')
          : await Hive.openBox<TestAttempt>('testAttempts');
      _attemptsSub = box.watch().listen((_) => refresh());
    } catch (e) {
      debugPrint('[DashboardProvider] failed to subscribe to testAttempts: $e');
    }
  }

  @override
  void dispose() {
    _attemptsSub?.cancel();
    super.dispose();
  }

  Future<void> _applyExams(List<SubscribedExam> exams) async {
    _exams = exams;
    final attempts = await _loadAttempts();
    _buildOverviewProgress(attempts);

    // Preserve selection if the same exam still exists; otherwise pick first
    final prevId = _selectedExam?.id;
    final target = exams.where((e) => e.id == prevId).firstOrNull
        ?? (exams.isNotEmpty ? exams.first : null);

    if (target != null) _selectExam(target, attempts);
  }

  /// Opens the testAttempts box if needed — works on all platforms including
  /// web (where the box may not be open if the home tab hasn't been visited).
  Future<List<TestAttempt>> _loadAttempts() async {
    try {
      final box = Hive.isBoxOpen('testAttempts')
          ? Hive.box<TestAttempt>('testAttempts')
          : await Hive.openBox<TestAttempt>('testAttempts');
      return box.values.toList();
    } catch (e) {
      debugPrint('[DashboardProvider] failed to open testAttempts: $e');
      return [];
    }
  }

  void _buildOverviewProgress(List<TestAttempt> attempts) {
    _overviewProgress = {
      for (final e in _exams)
        e.id: DashboardHelpers.overallProgressPercent(e, attempts),
    };
  }

  void _selectExam(SubscribedExam exam, List<TestAttempt> attempts) {
    _selectedExam = exam;
    _selectedStats = DashboardHelpers.computeExamStats(exam, attempts);
  }
}
