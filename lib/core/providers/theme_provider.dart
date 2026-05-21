import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode;

  ThemeMode get themeMode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider(SharedPreferences prefs) : _mode = _resolve(prefs);

  static ThemeMode _resolve(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    if (saved == null) {
      final oldBool = prefs.getBool('dark_mode');
      if (oldBool == true) return ThemeMode.dark;
      if (oldBool == false) return ThemeMode.light;
      return ThemeMode.system;
    }
    return switch (saved) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      _ => 'system',
    };
    await prefs.setString(_key, value);
    notifyListeners();
  }

  // Kept for backward compat — cycles light → dark → system
  Future<void> toggle() async {
    final next = switch (_mode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      _ => ThemeMode.light,
    };
    await setMode(next);
  }
}
