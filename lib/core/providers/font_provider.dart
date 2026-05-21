import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider extends ChangeNotifier {
  static const _key = 'font_family';
  static const _defaultFont = 'Inter';

  String _fontFamily;

  String get fontFamily => _fontFamily;

  FontProvider(SharedPreferences prefs)
      : _fontFamily = prefs.getString(_key) ?? _defaultFont;

  Future<void> setFont(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, family);
    notifyListeners();
  }
}
