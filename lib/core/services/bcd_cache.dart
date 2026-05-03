import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';

/// Single-fetch cache for the entire BCD category/subcategory/test tree.
///
/// ## Data source
/// All data comes from the `/self` (api/user/self/) endpoint via its
/// `bcd_dashboard` field — a nested tree that the backend already assembles in
/// one shot.  We never call the individual `api/v2/categories/`,
/// `api/v2/categories/{id}/subcategories/`, or `api/v2/categories/{id}/tests/`
/// endpoints for dashboard data.
///
/// ## Lifecycle
///   • On login / app start: [seedFromSelfResponse] is called by
///     [ApiService.fetchCurrentUser] with the `bcd_dashboard` list.
///   • On [syncNow] (pull-to-refresh): the cache is invalidated, then
///     [ApiService.fetchCurrentUser] is called again so [seedFromSelfResponse]
///     re-populates it from a fresh `/self` response.
///   • [ensureLoaded] is the general gate — it no-ops when already populated,
///     and calls [_fetchAll] (which hits `/self`) as a fallback when not.
///
/// ## Thread safety
/// Concurrent [ensureLoaded] callers wait on the same in-flight request.
class BcdCache {
  BcdCache._();
  static BcdCache? _instance;

  static BcdCache get instance => _instance ??= BcdCache._();

  static void invalidateIfInitialized() {
    _instance?.invalidate();
  }

  final ApiService _api = ApiService();

  // ── Cached data (raw API maps for drop-in compatibility with existing screens)

  List<Map<String, dynamic>>? _categories;
  final Map<int, List<Map<String, dynamic>>> _subcategories = {};
  final Map<int, List<Map<String, dynamic>>> _tests = {};

  Completer<void>? _loadCompleter;

  bool get isLoaded => _categories != null;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Ensures the cache is populated before data is read.
  ///
  /// Safe to call from multiple screens simultaneously —
  /// concurrent callers await the same in-flight request.
  Future<void> ensureLoaded() async {
    if (_categories != null) return;

    if (_loadCompleter != null) {
      await _loadCompleter!.future;
      return;
    }

    _loadCompleter = Completer<void>();
    try {
      await _fetchAll();
      _loadCompleter!.complete();
    } catch (e, st) {
      final completer = _loadCompleter!;
      _loadCompleter = null; // allow retry on next call
      completer.completeError(e, st);
      rethrow;
    }
  }

  /// Top-level BCD categories.
  List<Map<String, dynamic>> get categories => _categories ?? [];

  /// Subcategories for a parent [bcdId] (empty list if none or not loaded).
  List<Map<String, dynamic>> subcategoriesOf(int bcdId) =>
      _subcategories[bcdId] ?? [];

  /// Tests for a category or subcategory [bcdId].
  List<Map<String, dynamic>> testsOf(int bcdId) => _tests[bcdId] ?? [];

  /// Wipe the cache so the next [ensureLoaded] re-fetches.
  /// Call after subscription purchase or on logout.
  void invalidate() {
    _categories = null;
    _subcategories.clear();
    _tests.clear();
    _loadCompleter = null;
  }

  /// Populate the cache from the `bcd_dashboard` list already embedded in the
  /// `/self` response — called by [ApiService.fetchCurrentUser] right after
  /// the login / token-validation request.
  ///
  /// No-op if already loaded or a fetch is in-flight (the data is fresh enough).
  void seedFromSelfResponse(List<dynamic> bcdDashboard) {
    if (_categories != null || _loadCompleter != null) return;
    _applyDashboard(bcdDashboard);
    debugPrint('[BcdCache] seeded from /self: ${_categories!.length} categories');
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Fallback loader: re-fetches `/self` and populates from `bcd_dashboard`.
  ///
  /// Uses a single HTTP request rather than the old N+2 separate calls to
  /// api/v2/categories/, subcategories/, and tests/.
  Future<void> _fetchAll() async {
    debugPrint('[BcdCache] loading dashboard tree from /self…');
    final userData = await _api.fetchCurrentUser();
    final dashboard = (userData as Map<String, dynamic>?)?['bcd_dashboard'];
    if (dashboard is List && dashboard.isNotEmpty) {
      _applyDashboard(dashboard);
    } else {
      _categories ??= []; // no BCD access — mark loaded with empty list
    }
    debugPrint(
      '[BcdCache] loaded ${_categories?.length ?? 0} categories',
    );
  }

  /// Parses a raw `bcd_dashboard` list from the `/self` response and
  /// writes the results into [_categories], [_subcategories], and [_tests].
  ///
  /// Called from both [seedFromSelfResponse] (fast path, login) and
  /// [_fetchAll] (fallback path via [ensureLoaded]).
  void _applyDashboard(List<dynamic> bcdDashboard) {
    final cats = <Map<String, dynamic>>[];
    _subcategories.clear();
    _tests.clear();

    for (final raw in bcdDashboard) {
      final cat = Map<String, dynamic>.from(raw as Map);
      final bcdId = cat['bcd_id'] as int?;
      if (bcdId == null) continue;

      cats.add({
        'bcd_id': bcdId,
        'name': cat['name'],
        'is_subscribed': cat['is_subscribed'],
        'has_children': cat['has_children'],
        'sort_order': cat['sort_order'],
        'is_active': cat['is_active'],
      });

      // Subcategories (and their tests)
      final subs = cat['sub_categories'] as List<dynamic>? ?? [];
      if (subs.isNotEmpty) {
        final subList = <Map<String, dynamic>>[];
        for (final rawSub in subs) {
          final sub = Map<String, dynamic>.from(rawSub as Map);
          final subId = sub['bcd_id'] as int?;
          if (subId == null) continue;
          subList.add({
            'bcd_id': subId,
            'name': sub['name'],
            'is_subscribed': sub['is_subscribed'],
            'has_children': sub['has_children'],
            'sort_order': sub['sort_order'],
            'is_active': sub['is_active'],
          });
          _tests[subId] = (sub['tests'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();
        }
        _subcategories[bcdId] = subList;
      }

      // Tests directly on this root category (leaf categories)
      _tests[bcdId] = (cat['tests'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    _categories = cats;
  }
}
