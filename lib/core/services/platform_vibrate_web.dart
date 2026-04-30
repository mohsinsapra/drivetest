import 'dart:js_interop';
import 'package:web/web.dart';

void webVibrate(int durationMs) {
  try {
    window.navigator.vibrate(durationMs.toJS);
  } catch (_) {}
}

void webVibratePattern(List<int> pattern) {
  try {
    // Convert pattern to JSArray
    final jsArr = pattern.map((e) => e.toJS).toList().jsify()!;
    window.navigator.vibrate(jsArr);
  } catch (_) {}
}
