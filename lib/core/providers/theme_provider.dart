import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get themeMode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) {
      // Backward compat: migrate old bool key to new string key
      final oldBool = prefs.getBool('dark_mode');
      if (oldBool == true) {
        _mode = ThemeMode.dark;
      } else if (oldBool == false) {
        _mode = ThemeMode.light;
      } else {
        _mode = ThemeMode.system;
      }
    } else {
      _mode = switch (saved) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
    }
    notifyListeners();
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
