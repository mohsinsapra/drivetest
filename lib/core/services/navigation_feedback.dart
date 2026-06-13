import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'platform_vibrate_native.dart'
    if (dart.library.js_interop) 'platform_vibrate_web.dart';

const int _navigationFeedbackDurationMs = 15;

final NavigationFeedbackService _defaultNavigationFeedbackService =
    NavigationFeedbackService();

Future<void> playNavigationFeedback() {
  return _defaultNavigationFeedbackService.play();
}

/// Crisp double-tap — correct answer selected in instant-check mode.
Future<void> vibrateCorrectAnswer() => _vibrate(pattern: [0, 60, 50, 60]);

/// Short error buzz — wrong answer selected in instant-check mode.
Future<void> vibrateWrongAnswer() => _vibrate(durationMs: 250);

/// Celebration — test passed.
Future<void> vibratePass() => _vibrate(pattern: [0, 100, 60, 180, 60, 260]);

/// Failure — test failed.
Future<void> vibrateFail() => _vibrate(durationMs: 400);

/// Exam-level pass — maximum celebration: three escalating heavy impacts.
Future<void> vibrateExamPass() async {
  if (kIsWeb) {
    webVibratePattern([0, 80, 50, 130, 50, 200, 50, 280, 50, 380]);
    return;
  }
  try {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 130));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 130));
    await HapticFeedback.heavyImpact();
  } on MissingPluginException {
    // Not available in test environments.
  } on PlatformException {
    // Ignore.
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Vibration.vibrate(
          pattern: [0, 80, 50, 130, 50, 200, 50, 280, 50, 380]);
    } on MissingPluginException {
      // Ignore.
    } on PlatformException {
      // Ignore.
    } on UnsupportedError {
      // Ignore.
    }
  }
}

/// Exam-level fail — two heavy thumps, less intense than pass.
Future<void> vibrateExamFail() async {
  if (kIsWeb) {
    webVibratePattern([0, 220, 120, 220]);
    return;
  }
  try {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 140));
    await HapticFeedback.heavyImpact();
  } on MissingPluginException {
    // Not available in test environments.
  } on PlatformException {
    // Ignore.
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Vibration.vibrate(pattern: [0, 220, 120, 220]);
    } on MissingPluginException {
      // Ignore.
    } on PlatformException {
      // Ignore.
    } on UnsupportedError {
      // Ignore.
    }
  }
}

/// Brief tap — login or logout confirmed.
Future<void> vibrateLoginLogout() => _vibrate(durationMs: 100);

/// Unified vibration helper.
///
/// Strategy:
///  - Web  → navigator.vibrate() via js_interop (works in Chrome on Android)
///  - iOS  → HapticFeedback (CHHapticEngine via method channel)
///  - Android → HapticFeedback (View.performHapticFeedback) AND
///              Vibration.vibrate() (Vibrator service).
///             Using both maximises coverage across tablets and phones.
Future<void> _vibrate({int? durationMs, List<int>? pattern}) async {
  if (kIsWeb) {
    if (pattern != null) {
      webVibratePattern(pattern);
    } else {
      webVibrate(durationMs ?? 150);
    }
    return;
  }

  final ms = durationMs ?? 150;

  // HapticFeedback works on iOS and on Android via View.performHapticFeedback.
  // It respects system haptic settings and works on devices that have haptic
  // hardware even when the Vibrator service is absent (some tablets).
  try {
    if (ms <= 80) {
      await HapticFeedback.lightImpact();
    } else if (ms <= 220) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.heavyImpact();
    }
  } on MissingPluginException {
    // Not available in test environments.
  } on PlatformException {
    // Ignore platform-level failures.
  }

  // On Android, also drive the Vibrator service directly.  The Java-side
  // Vibration.java already guards with vibrator.hasVibrator(), so calling
  // this on devices without a vibrator is safe (no-op).
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      if (pattern != null) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        await Vibration.vibrate(duration: ms);
      }
    } on MissingPluginException {
      // Ignore.
    } on PlatformException {
      // Ignore.
    } on UnsupportedError {
      // Ignore.
    }
  }
}

typedef PlatformResolver = TargetPlatform Function();
typedef HapticSelectionClick = Future<void> Function();

class NavigationFeedbackService {
  NavigationFeedbackService({
    NavigationFeedbackDriver? driver,
    PlatformResolver? platformResolver,
    bool? isWeb,
    HapticSelectionClick? selectionClick,
  })  : _driver = driver ?? const VibrationNavigationFeedbackDriver(),
        _platformResolver = platformResolver ?? _defaultPlatformResolver,
        _isWeb = isWeb ?? kIsWeb,
        _selectionClick = selectionClick ?? HapticFeedback.selectionClick;

  final NavigationFeedbackDriver _driver;
  final PlatformResolver _platformResolver;
  final bool _isWeb;
  final HapticSelectionClick _selectionClick;

  Future<void> play() async {
    if (_isWeb || _platformResolver() == TargetPlatform.android) {
      await _playVibration();
      return;
    }
    await _selectionClick();
  }

  Future<void> _playVibration() async {
    try {
      if (await _driver.hasVibrationSupport()) {
        await _driver.vibrate(durationMs: _navigationFeedbackDurationMs);
      }
    } on MissingPluginException {
      // Ignore unsupported environments such as tests or browsers without support.
    } on PlatformException {
      // Ignore platform-level vibration failures and leave navigation unaffected.
    } on UnsupportedError {
      // Ignore unsupported browser/device combinations.
    }
  }
}

abstract interface class NavigationFeedbackDriver {
  Future<bool> hasVibrationSupport();

  Future<void> vibrate({required int durationMs});
}

class VibrationNavigationFeedbackDriver implements NavigationFeedbackDriver {
  const VibrationNavigationFeedbackDriver();

  @override
  Future<bool> hasVibrationSupport() async {
    return Vibration.hasVibrator();
  }

  @override
  Future<void> vibrate({required int durationMs}) {
    return Vibration.vibrate(duration: durationMs);
  }
}

TargetPlatform _defaultPlatformResolver() => defaultTargetPlatform;
