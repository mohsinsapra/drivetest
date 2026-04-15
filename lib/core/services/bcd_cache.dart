import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';

/// Single-fetch cache for the entire BCD category/subcategory/test tree.
///
/// Call [ensureLoaded] before reading any data. Subsequent calls are no-ops
/// (returns immediately from memory). Screens that previously called
/// [ApiService.fetchBCDAllCategories], [fetchBCDSubcategories], or
/// [fetchBCDTests] now call this cache instead.
///
/// After a subscription purchase, call [invalidate] so the next
/// [ensureLoaded] re-fetches fresh subscription flags.
class BcdCache {
  BcdCache._();
  static final BcdCache instance = BcdCache._();

  final ApiService _api = ApiService();

  // ── Cached data (raw API maps for drop-in compatibility with existing screens)

  List<Map<String, dynamic>>? _categories;
  final Map<int, List<Map<String, dynamic>>> _subcategories = {};
  final Map<int, List<Map<String, dynamic>>> _tests = {};

  Completer<void>? _loadCompleter;

  bool get isLoaded => _categories != null;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fetches everything once. Safe to call from multiple screens simultaneously —
  /// parallel callers wait on the same in-flight request.
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

  /// Call after subscription purchase so next [ensureLoaded] re-fetches.
  void invalidate() {
    _categories = null;
    _subcategories.clear();
    _tests.clear();
    _loadCompleter = null;
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _fetchAll() async {
    debugPrint('[BcdCache] fetching full BCD tree…');

    final rawCats = await _api.fetchBCDAllCategories();
    final cats =
        rawCats.whereType<Map<String, dynamic>>().toList();
    _categories = cats;

    for (final cat in cats) {
      final bcdId = cat['bcd_id'] as int?;
      if (bcdId == null) continue;

      if (cat['has_children'] == true) {
        // Fetch subcategories
        final rawSubs = await _api.fetchBCDSubcategories(bcdId);
        final subs =
            rawSubs.whereType<Map<String, dynamic>>().toList();
        _subcategories[bcdId] = subs;

        // Fetch tests for every subcategory
        for (final sub in subs) {
          final subId = sub['bcd_id'] as int?;
          if (subId == null) continue;
          await _fetchTests(subId);
        }
      } else {
        // Leaf category — fetch tests directly
        await _fetchTests(bcdId);
      }
    }

    debugPrint(
      '[BcdCache] loaded ${cats.length} categories, '
      '${_subcategories.values.expand((s) => s).length} subcategories, '
      '${_tests.values.expand((t) => t).length} tests',
    );
  }

  Future<void> _fetchTests(int bcdId) async {
    try {
      final raw = await _api.fetchBCDTests(bcdId);
      _tests[bcdId] = raw.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('[BcdCache] failed fetching tests for bcd_id=$bcdId: $e');
      _tests[bcdId] = [];
    }
  }
}
