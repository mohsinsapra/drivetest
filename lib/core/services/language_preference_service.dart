import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which non-Swedish translation language the user uses most often,
/// so screens can pre-fetch it in the background before the user long-presses.
class LanguagePreferenceService {
  static const String _prefix = 'lang_usage_';

  /// Call this every time the user explicitly picks a language.
  /// Swedish ('sv') is the native language — no need to track it.
  static Future<void> record(String langCode) async {
    final code = langCode.toLowerCase();
    if (code == 'sv') return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$code';
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  /// Returns the most-used non-SV language code (uppercase, e.g. 'EN', 'AR'),
  /// or null if the user has never switched away from Swedish.
  static Future<String?> getMostUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    if (keys.isEmpty) return null;

    String? best;
    int bestCount = 0;
    for (final k in keys) {
      final count = prefs.getInt(k) ?? 0;
      if (count > bestCount) {
        bestCount = count;
        best = k.substring(_prefix.length).toUpperCase();
      }
    }
    return best;
  }
}
