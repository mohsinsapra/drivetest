import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_progress_service.dart';
import '../helpers/dashboard_helpers.dart';
import '../models/dashboard_stats.dart';
import '../models/subscribed_exam.dart';
import '../repository/dashboard_repository.dart';
import '../repository/exam_sync_service.dart';

enum DashboardStatus { idle, loading, loaded, error }

enum DashboardErrorKind { network, server, unknown }

enum PeriodFilter { today, sevenDays, thisMonth, all }

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

  /// All loaded test attempts — used by UI for per-batch history and resume.
  List<TestAttempt> _attempts = [];
  List<TestAttempt> get attempts => _attempts;

  /// Pre-computed stats for every exam, keyed by exam id.
  /// Rebuilt whenever attempts or period changes; [selectExam] is a O(1) lookup.
  Map<String, ExamDashboardStats> _statsCache = {};
  Map<String, ExamDashboardStats> get statsCache => _statsCache;

  /// True while background API sync is running (after initial load).
  bool _syncing = false;
  bool get syncing => _syncing;

  /// True during the brief exam-to-exam handoff, while the previous content
  /// remains visible and the next exam is prepared for display.
  bool _switching = false;
  bool get switching => _switching;

  static const Duration _examSwitchDuration = Duration(milliseconds: 180);
  Timer? _examSwitchTimer;

  String? _error;
  String? get error => _error;

  DashboardErrorKind _errorKind = DashboardErrorKind.unknown;
  DashboardErrorKind get errorKind => _errorKind;

  /// Timestamp of the last successful API sync. Used to avoid redundant calls.
  DateTime? _lastSyncedAt;

  /// Incremented on every [reset]. In-flight async operations capture their
  /// generation at start and abort their write-back if it changed, preventing
  /// a background sync from restoring a previous user's data after logout.
  int _generation = 0;

  /// Subscription to testAttempts Hive box — triggers refresh on any write.
  StreamSubscription<BoxEvent>? _attemptsSub;

  /// Debounce timer for refresh() — coalesces rapid watcher events into one.
  Timer? _refreshDebounce;

  int _weeklyGoal = 5;

  PeriodFilter _period = PeriodFilter.thisMonth;
  PeriodFilter get period => _period;

  List<TestAttempt> get _periodAttempts {
    final now = DateTime.now();
    return switch (_period) {
      PeriodFilter.today => _attempts
          .where((a) =>
              a.dateTime.year == now.year &&
              a.dateTime.month == now.month &&
              a.dateTime.day == now.day)
          .toList(),
      PeriodFilter.sevenDays => _attempts
          .where(
              (a) => a.dateTime.isAfter(now.subtract(const Duration(days: 7))))
          .toList(),
      PeriodFilter.thisMonth => _attempts
          .where((a) =>
              a.dateTime.year == now.year && a.dateTime.month == now.month)
          .toList(),
      PeriodFilter.all => _attempts,
    };
  }

  Future<void> setPeriod(PeriodFilter p) async {
    if (_period == p) return;
    _period = p;
    await _rebuildStatsCache();
    _selectedStats =
        _selectedExam != null ? _statsCache[_selectedExam!.id] : null;
    notifyListeners();
  }

  Future<void> setWeeklyGoal(int goal) async {
    if (_weeklyGoal == goal) return;
    _weeklyGoal = goal;
    if (_selectedExam != null && _attempts.isNotEmpty) {
      await _rebuildStatsCache();
      _selectedStats = _statsCache[_selectedExam!.id];
      notifyListeners();
    }
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_status == DashboardStatus.loading) return;

    if (_status == DashboardStatus.loaded &&
        _exams.isNotEmpty &&
        _lastSyncedAt != null &&
        DateTime.now().difference(_lastSyncedAt!) <
            const Duration(minutes: 10)) {
      return;
    }

    _generation++;
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    _attemptsSub?.cancel();
    _attemptsSub = null;
    _exams = [];
    _attempts = [];
    _selectedExam = null;
    _selectedStats = null;
    _switching = false;
    _overviewProgress = {};
    _statsCache = {};
    _error = null;
    _syncing = false;
    _lastSyncedAt = null;
    _status = DashboardStatus.loading;
    notifyListeners();

    _syncFromApi();
    _subscribeToAttempts();
  }

  /// Clears stats immediately (triggers shimmer), then resolves on the next
  /// microtask so the skeleton gets one frame to render before real data lands.
  void selectExam(SubscribedExam exam) {
    if (_selectedExam?.id == exam.id) return;
    final nextStats = _statsCache[exam.id] ??
        DashboardHelpers.computeExamStats(exam, _periodAttempts, _attempts,
            weeklyGoal: _weeklyGoal);
    _examSwitchTimer?.cancel();
    _selectedExam = exam;
    if (_selectedStats == null) {
      _selectedStats = nextStats;
      _switching = false;
      notifyListeners();
      return;
    }
    _switching = true;
    notifyListeners();

    _examSwitchTimer = Timer(_examSwitchDuration, () {
      if (_selectedExam?.id != exam.id) return;
      _selectedStats = nextStats;
      _switching = false;
      _examSwitchTimer = null;
      notifyListeners();
    });
  }

  /// Debounced so rapid Hive writes (e.g. bulk sync) collapse into one refresh.
  void refresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 50), _doRefresh);
  }

  Future<void> _doRefresh() async {
    final attempts = await _loadAttempts();
    _attempts = attempts;
    _buildOverviewProgress(attempts);
    await _rebuildStatsCache();
    _selectedStats =
        _selectedExam != null ? _statsCache[_selectedExam!.id] : null;
    notifyListeners();
  }

  Future<void> syncNow() async {
    BcdCache.instance.invalidate();
    await DioClient().clearCache();
    try {
      final box = await AppStorage.subscribedExamsBox();
      await box.clear();
    } catch (e) {
      debugPrint('[DashboardProvider] syncNow: Hive clear failed: $e');
    }
    try {
      await ApiService().fetchCurrentUser(forceRefresh: true);
    } catch (e) {
      debugPrint('[DashboardProvider] syncNow: /self re-fetch failed: $e');
    }
    await _syncFromApi();
  }

  void reset() {
    _generation++;
    _examSwitchTimer?.cancel();
    _examSwitchTimer = null;
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    _attemptsSub?.cancel();
    _attemptsSub = null;
    _exams = [];
    _attempts = [];
    _selectedExam = null;
    _selectedStats = null;
    _overviewProgress = {};
    _statsCache = {};
    _lastSyncedAt = null;
    _syncing = false;
    _error = null;
    _errorKind = DashboardErrorKind.unknown;
    _status = DashboardStatus.idle;
    _switching = false;
    notifyListeners();
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<void> _syncFromApi() async {
    if (_syncing) return;
    final shouldNotifySyncStart = _status != DashboardStatus.loading;
    _syncing = true;
    final gen = _generation;
    if (shouldNotifySyncStart) notifyListeners();

    try {
      final fetched = await _sync.fetchSubscribedExams();
      if (_generation != gen) return;

      if (fetched.isNotEmpty) {
        await _repo.saveAll(fetched);
        if (_generation != gen) return;
        final refreshed = await _repo.loadSubscribedExams();
        if (_generation != gen) return;
        await _applyExams(refreshed);
        _status = DashboardStatus.loaded;
      } else if (_exams.isEmpty) {
        _status = DashboardStatus.loaded;
      }
      _lastSyncedAt = DateTime.now();
    } catch (e) {
      debugPrint('[DashboardProvider] API sync failed: $e');
      if (_generation == gen && _exams.isEmpty) {
        _error = e.toString();
        _errorKind = _classifyError(e);
        _status = DashboardStatus.error;
      }
    } finally {
      if (_generation == gen) _syncing = false;
      notifyListeners();
    }
  }

  DashboardErrorKind _classifyError(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return DashboardErrorKind.network;
      }
      final status = e.response?.statusCode;
      if (status != null && status >= 500) return DashboardErrorKind.server;
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('connection refused') ||
        msg.contains('socketexception') ||
        msg.contains('network') ||
        msg.contains('connection error')) {
      return DashboardErrorKind.network;
    }
    return DashboardErrorKind.unknown;
  }

  Future<void> _subscribeToAttempts() async {
    if (_attemptsSub != null) return;
    try {
      final box = await AppStorage.testAttemptsBox();
      _attemptsSub = box.watch().listen((_) => refresh());
    } catch (e) {
      debugPrint('[DashboardProvider] failed to subscribe to testAttempts: $e');
    }
  }

  @override
  void dispose() {
    _examSwitchTimer?.cancel();
    _refreshDebounce?.cancel();
    _attemptsSub?.cancel();
    super.dispose();
  }

  Future<void> _applyExams(List<SubscribedExam> exams) async {
    _exams = exams;
    final attempts = await _loadAttempts();
    _attempts = attempts;
    _buildOverviewProgress(attempts);
    await _rebuildStatsCache();

    final prevId = _selectedExam?.id;
    SubscribedExam? target = exams.where((e) => e.id == prevId).firstOrNull;
    if (target == null && exams.isNotEmpty) {
      SubscribedExam? active;
      DateTime? latestDate;
      for (final e in exams) {
        final d = _statsCache[e.id]?.lastAttemptDate;
        if (d != null && (latestDate == null || d.isAfter(latestDate))) {
          latestDate = d;
          active = e;
        }
      }
      target = active ?? exams.first;
    }

    if (target != null) {
      _examSwitchTimer?.cancel();
      _examSwitchTimer = null;
      _selectedExam = target;
      _selectedStats = _statsCache[target.id];
      _switching = false;
    }
  }

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
    _overviewProgress =
        DashboardHelpers.buildOverviewProgress(_exams, attempts);
  }

  /// Pre-computes stats for every exam using the current period filter.
  /// Yields to the event loop between each exam so long computations
  /// (many batches × many attempts) don't block UI frames.
  Future<void> _rebuildStatsCache() async {
    final filtered = _periodAttempts;
    final exams = _exams;
    final all = _attempts;
    final goal = _weeklyGoal;
    final gen = _generation;

    // Load smart-learning stats for all BCD exams in one pass.
    final smartSvc = SmartProgressService();
    final bcdExamIds = <String, int>{};
    for (final exam in exams) {
      if (!exam.isBcd) continue;
      final bcdId = int.tryParse(exam.id);
      if (bcdId != null) {
        bcdExamIds[exam.id] = bcdId;
      }
    }
    final smartByBcdId = await smartSvc.examSmartStatsByExam(bcdExamIds.values);

    final result = <String, ExamDashboardStats>{};
    for (final exam in exams) {
      // Give the UI thread a frame between heavy per-exam computations.
      await Future.microtask(() {});
      if (_generation != gen) return;
      final bcdId = bcdExamIds[exam.id];
      final smart = bcdId == null ? null : smartByBcdId[bcdId];
      result[exam.id] = DashboardHelpers.computeExamStats(
        exam, filtered, all,
        weeklyGoal: goal,
        smartChunksMastered: smart?.chunksMastered ?? 0,
        smartChunksTotal: smart?.chunksTotal ?? 0,
        weakQuestionsCount: smart?.weakQuestions ?? 0,
      );
    }
    if (_generation != gen) return;
    _statsCache = result;
  }
}
