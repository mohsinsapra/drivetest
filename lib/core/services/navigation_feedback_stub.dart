import 'dart:io';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

Future<void> playNavigationFeedback() async {
  if (Platform.isAndroid) {
    final bool hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(duration: 30);
    }
  } else {
    HapticFeedback.selectionClick();
  }
}
