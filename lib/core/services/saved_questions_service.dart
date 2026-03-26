import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';

class SavedQuestionsService {
  static final ApiService _api = ApiService();

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
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey(
            licenceId: licenceId,
            categoryId: categoryId,
            bcdCategoryId: bcdCategoryId)) ??
        [];
    return list.toSet();
  }

  static Future<Set<String>> refreshFromBackend(
      {String? licenceId, String? categoryId, int? bcdCategoryId}) async {
    final remoteIds = await _api.fetchSavedQuestionIds(
      scopeType: _scopeType(bcdCategoryId: bcdCategoryId),
      licenceId: licenceId,
      categoryId: categoryId,
      bcdCategoryId: bcdCategoryId,
    );
    await _setSavedIds(remoteIds,
        licenceId: licenceId,
        categoryId: categoryId,
        bcdCategoryId: bcdCategoryId);
    return remoteIds;
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
}
