import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';

class SavedQuestionsService {
  static final ApiService _api = ApiService();
  static const Duration _syncCooldown = Duration(seconds: 45);
  static final Map<String, Set<String>> _memoryCache = {};
  static final Map<String, DateTime> _lastSyncedAt = {};
  static final Map<String, Future<Set<String>>> _inFlightSync = {};

  static String _scopeKey(
      {String? licenceId, String? categoryId, int? bcdCategoryId}) {
    if (bcdCategoryId != null) {
      return 'bcd:$bcdCategoryId';
    }
    return 'legacy:${licenceId ?? ''}:${categoryId ?? ''}';
  }

  static String _storageKey(
      {String? licenceId, String? categoryId, int? bcdCategoryId}) {
    return 'saved_question_ids_${_scopeKey(licenceId: licenceId, categoryId: categoryId, bcdCategoryId: bcdCategoryId)}';
  }

  static String _scopeType({int? bcdCategoryId}) {
    return bcdCategoryId != null ? 'bcd' : 'legacy';
  }

  static Future<void> _setSavedIds(Set<String> ids,
      {String? licenceId, String? categoryId, int? bcdCategoryId}) async {
    final scope = _scopeKey(
      licenceId: licenceId,
      categoryId: categoryId,
      bcdCategoryId: bcdCategoryId,
    );
    _memoryCache[scope] = Set<String>.from(ids);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey(
          licenceId: licenceId,
          categoryId: categoryId,
          bcdCategoryId: bcdCategoryId),
      ids.toList(),
    );
  }

  static Future<Set<String>> getSavedIdsScoped(
      {String? licenceId, String? categoryId, int? bcdCategoryId}) async {
    final scope = _scopeKey(
      licenceId: licenceId,
      categoryId: categoryId,
      bcdCategoryId: bcdCategoryId,
    );
    final mem = _memoryCache[scope];
    if (mem != null) {
      return Set<String>.from(mem);
    }

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey(
            licenceId: licenceId,
            categoryId: categoryId,
            bcdCategoryId: bcdCategoryId)) ??
        [];
    final saved = list.toSet();
    _memoryCache[scope] = Set<String>.from(saved);
    return saved;
  }

  static Future<Set<String>> refreshFromBackend(
      {String? licenceId,
      String? categoryId,
      int? bcdCategoryId,
      bool force = false}) async {
    final scope = _scopeKey(
      licenceId: licenceId,
      categoryId: categoryId,
      bcdCategoryId: bcdCategoryId,
    );

    if (!force) {
      final inFlight = _inFlightSync[scope];
      if (inFlight != null) return inFlight;

      final lastSynced = _lastSyncedAt[scope];
      if (lastSynced != null &&
          DateTime.now().difference(lastSynced) < _syncCooldown) {
        return getSavedIdsScoped(
          licenceId: licenceId,
          categoryId: categoryId,
          bcdCategoryId: bcdCategoryId,
        );
      }
    }

    final future = () async {
      final remoteIds = await _api.fetchSavedQuestionIds(
        scopeType: _scopeType(bcdCategoryId: bcdCategoryId),
        licenceId: licenceId,
        categoryId: categoryId,
        bcdCategoryId: bcdCategoryId,
      );
      await _setSavedIds(
        remoteIds,
        licenceId: licenceId,
        categoryId: categoryId,
        bcdCategoryId: bcdCategoryId,
      );
      _lastSyncedAt[scope] = DateTime.now();
      return remoteIds;
    }();

    _inFlightSync[scope] = future;
    try {
      return await future;
    } finally {
      _inFlightSync.remove(scope);
    }
  }

  static Future<bool> toggleSavedScoped(
    String questionId, {
    required String questionText,
    String? licenceId,
    String? categoryId,
    int? bcdCategoryId,
  }) async {
    if (questionId.isEmpty) return false;
    final saved = await getSavedIdsScoped(
        licenceId: licenceId,
        categoryId: categoryId,
        bcdCategoryId: bcdCategoryId);
    final remote = await _api.toggleSavedQuestion(
      questionId: questionId,
      questionText: questionText,
      scopeType: _scopeType(bcdCategoryId: bcdCategoryId),
      licenceId: licenceId,
      categoryId: categoryId,
      bcdCategoryId: bcdCategoryId,
    );

    if (remote == null) {
      if (saved.contains(questionId)) {
        saved.remove(questionId);
      } else {
        saved.add(questionId);
      }
      await _setSavedIds(saved,
          licenceId: licenceId,
          categoryId: categoryId,
          bcdCategoryId: bcdCategoryId);
      return saved.contains(questionId);
    }

    if (remote) {
      saved.add(questionId);
    } else {
      saved.remove(questionId);
    }
    await _setSavedIds(saved,
        licenceId: licenceId,
        categoryId: categoryId,
        bcdCategoryId: bcdCategoryId);
    return remote;
  }

  static Future<Set<String>> getSavedIds() async {
    return getSavedIdsScoped();
  }

  static Future<void> saveQuestion(String questionId) async {
    if (questionId.isEmpty) return;
    final saved = await getSavedIds();
    saved.add(questionId);
    await _setSavedIds(saved);
  }

  static Future<void> removeQuestion(String questionId) async {
    final saved = await getSavedIds();
    saved.remove(questionId);
    await _setSavedIds(saved);
  }

  static Future<bool> isQuestionSaved(String questionId) async {
    if (questionId.isEmpty) return false;
    final saved = await getSavedIds();
    return saved.contains(questionId);
  }

  static Future<bool> toggleSaved(String questionId) async {
    if (questionId.isEmpty) return false;
    return toggleSavedScoped(questionId, questionText: '');
  }

  /// Wipes the in-memory cache. Called by [AppStorage.clearUserData] on logout
  /// so a new user's bookmarks are fetched fresh from the API/SharedPreferences.
  static void clearMemoryCache() {
    _memoryCache.clear();
    _lastSyncedAt.clear();
    _inFlightSync.clear();
  }
}
