import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import '../helpers/dashboard_helpers.dart';
import '../models/dashboard_stats.dart';
import '../models/subscribed_exam.dart';
import '../repository/dashboard_repository.dart';
import '../repository/exam_sync_service.dart';

enum DashboardStatus { idle, loading, loaded, error }

/// ChangeNotifier provider for the exam dashboard.
///
/// Flow on [init]:
///   1. BcdCache is already seeded from /self (api/user/self/) during login.
///   2. [_syncFromApi] builds [SubscribedExam] objects from BcdCache (fast,
///      no extra network call) and persists them to Hive.
///   3. UI is notified once fresh data is ready — stale local data is never
///      shown as an intermediate state.
///
/// [TestAttempt] data is read from the 'testAttempts' Hive box via
/// [AppStorage] — no duplication of attempt storage.
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

  /// Incremented on every [reset]. In-flight async operations capture their
  /// generation at start and abort their write-back if it changed, preventing
  /// a background sync from restoring a previous user's data after logout.
  int _generation = 0;

  /// Subscription to testAttempts Hive box — triggers refresh on any write.
  StreamSubscription<BoxEvent>? _attemptsSub;

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_status == DashboardStatus.loading) return;

    // Within the same session, skip a re-init if data is fresh (tab switch).
    // The guard requires status == loaded (i.e. a successful prior fetch in
    // THIS session) AND a recent sync timestamp — both are cleared by reset().
    if (_status == DashboardStatus.loaded &&
        _exams.isNotEmpty &&
        _lastSyncedAt != null &&
        DateTime.now().difference(_lastSyncedAt!) <
            const Duration(minutes: 10)) {
      return;
    }

    // Full clean-slate before loading — guarantees no stale data from a
    // previous session is ever shown, regardless of whether reset() was called.
    _generation++;                 // kills any in-flight _syncFromApi
    _attemptsSub?.cancel();        // drop the old box subscription
    _attemptsSub = null;
    _exams = [];
    _selectedExam = null;
    _selectedStats = null;
    _overviewProgress = {};
    _error = null;
    _syncing = false;
    _lastSyncedAt = null;
    _status = DashboardStatus.loading;
    notifyListeners();

    // Populate from the API — BcdCache is already seeded from /self during
    // login/splash so this is fast and never shows stale local data.
    _syncFromApi();

    // Subscribe to testAttempts so completing a test refreshes stats live.
    _subscribeToAttempts();
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

  /// Force a full re-fetch from the API (pull-to-refresh / sync button).
  ///
  /// Steps:
  ///   1. Bust the in-memory BCD tree and the Dio HTTP response cache.
  ///   2. Re-fetch `/self` — this re-seeds [BcdCache] from the `bcd_dashboard`
  ///      field in a single network request (no separate category/test calls).
  ///   3. Run [_syncFromApi] — [BcdCache.ensureLoaded] is now a no-op because
  ///      step 2 already populated the cache with fresh data.
  Future<void> syncNow() async {
    BcdCache.instance.invalidate();
    await DioClient().clearCache();
    try {
      await ApiService().fetchCurrentUser(); // re-seeds BcdCache from fresh /self
    } catch (e) {
      debugPrint('[DashboardProvider] syncNow: /self re-fetch failed: $e');
      // Continue — _syncFromApi will re-try via ensureLoaded
    }
    await _syncFromApi();
  }

  /// Wipe all in-memory state so a freshly logged-in user starts clean.
  /// Call this on logout before the next user's session begins.
  void reset() {
    _generation++;          // invalidates any in-flight _syncFromApi write-back
    _attemptsSub?.cancel();
    _attemptsSub = null;
    _exams = [];
    _selectedExam = null;
    _selectedStats = null;
    _overviewProgress = {};
    _lastSyncedAt = null;
    _syncing = false;
    _error = null;
    _status = DashboardStatus.idle;
    notifyListeners();
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<void> _syncFromApi() async {
    if (_syncing) return;
    _syncing = true;
    final gen = _generation; // capture before first await
    notifyListeners();

    try {
      final fetched = await _sync.fetchSubscribedExams();
      // Abort if reset() was called while we were awaiting — a new user session
      // has started and we must not write this user's data back to Hive/state.
      if (_generation != gen) return;

      if (fetched.isNotEmpty) {
        await _repo.saveAll(fetched);
        if (_generation != gen) return; // check again after the save await
        final refreshed = await _repo.loadSubscribedExams();
        if (_generation != gen) return;
        await _applyExams(refreshed);
        _status = DashboardStatus.loaded;
      } else if (_exams.isEmpty) {
        // API returned nothing and cache is also empty
        _status = DashboardStatus.loaded; // show empty state, not error
      }
      _lastSyncedAt = DateTime.now();
    } catch (e) {
      debugPrint('[DashboardProvider] API sync failed: $e');
      if (_generation == gen && _exams.isEmpty) {
        // Primary load failed with no data to fall back on — show error state.
        _error = e.toString();
        _status = DashboardStatus.error;
      }
      // If _exams is already populated (background refresh), keep showing it.
    } finally {
      if (_generation == gen) {
        // Only clear the syncing flag for the generation that started it
        _syncing = false;
      }
      notifyListeners();
    }
  }

  /// Subscribes to the testAttempts Hive box. Any write (test completed or
  /// paused) triggers a stats refresh so the dashboard stays current without
  /// the user having to pull-to-refresh.
  Future<void> _subscribeToAttempts() async {
    if (_attemptsSub != null) return; // already subscribed
    try {
      final box = await AppStorage.testAttemptsBox();
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
      final box = await AppStorage.testAttemptsBox();
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
