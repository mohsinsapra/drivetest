import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:taxi_exam_app/core/constants/language_options.dart';

enum TtsState { playing, stopped }

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  List<dynamic> supportedLanguages = [];
  final FlutterTts flutterTts = FlutterTts();
  TtsState ttsState = TtsState.stopped;
  bool _isInitialized = false;

  TtsService._internal() {
    _initialize();
    flutterTts.setCompletionHandler(() {
      ttsState = TtsState.stopped;
    });
  }

  Future<void> _initialize() async {
    if (!_isInitialized) {
      supportedLanguages = await flutterTts.getLanguages;
      _isInitialized = true;
    }
  }

  String? getTtsCode(String code) {
    final langEntry = languageOptions.firstWhere(
      (lang) => lang['code'] == code.toUpperCase(),
      orElse: () => {},
    );
    return langEntry['ttsCode'];
  }

  /// ✅ Convert to async
  Future<bool> isTtsLanguageSupported(String code) async {
    if (!_isInitialized) {
      await _initialize();
    }

    final ttsCode = getTtsCode(code);
    return ttsCode != null &&
        ttsCode.isNotEmpty &&
        supportedLanguages.contains(ttsCode);
  }

  Future<void> speak(
    String text,
    String languageCode,
    VoidCallback onStateChange,
  ) async {
    final flutterLangCode = getTtsCode(languageCode);
    if (flutterLangCode == null || flutterLangCode.isEmpty) {
      debugPrint("Language '$languageCode' is not mapped to a TTS code.");
      return;
    }

    if (ttsState == TtsState.playing) {
      await flutterTts.stop();
      ttsState = TtsState.stopped;
      onStateChange();
      return;
    }

    if (!_isInitialized) {
      await _initialize();
    }

    if (supportedLanguages.contains(flutterLangCode)) {
      await flutterTts.setLanguage(flutterLangCode);
      await flutterTts.setPitch(1);
      await flutterTts.speak(text);
      ttsState = TtsState.playing;
      onStateChange();
    } else {
      debugPrint("TTS language code '$flutterLangCode' is not supported.");
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
    ttsState = TtsState.stopped;
  }

  String getLanguageFlag(String code) {
    final entry = languageOptions.firstWhere(
      (lang) => lang['code'] == code.toUpperCase(),
      orElse: () => {},
    );

    final label = entry['label'];
    if (label != null && label.isNotEmpty) {
      return label.split(' ').first;
    }

    return '🌐';
  }
}
