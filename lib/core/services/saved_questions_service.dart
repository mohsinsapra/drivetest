import 'package:shared_preferences/shared_preferences.dart';

class SavedQuestionsService {
  static const String _key = 'saved_question_ids';

  static Future<Set<String>> getSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  static Future<void> saveQuestion(String questionId) async {
    if (questionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = await getSavedIds();
    saved.add(questionId);
    await prefs.setStringList(_key, saved.toList());
  }

  static Future<void> removeQuestion(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await getSavedIds();
    saved.remove(questionId);
    await prefs.setStringList(_key, saved.toList());
  }

  static Future<bool> isQuestionSaved(String questionId) async {
    if (questionId.isEmpty) return false;
    final saved = await getSavedIds();
    return saved.contains(questionId);
  }

  static Future<bool> toggleSaved(String questionId) async {
    if (questionId.isEmpty) return false;
    final saved = await getSavedIds();
    if (saved.contains(questionId)) {
      await removeQuestion(questionId);
      return false;
    } else {
      await saveQuestion(questionId);
      return true;
    }
  }
}
