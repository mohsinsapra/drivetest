import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

const int _navigationFeedbackDurationMs = 15;

final NavigationFeedbackService _defaultNavigationFeedbackService =
    NavigationFeedbackService();

Future<void> playNavigationFeedback() {
  return _defaultNavigationFeedbackService.play();
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
    return await Vibration.hasVibrator();
  }

  @override
  Future<void> vibrate({required int durationMs}) {
    return Vibration.vibrate(duration: durationMs);
  }
}

TargetPlatform _defaultPlatformResolver() => defaultTargetPlatform;
