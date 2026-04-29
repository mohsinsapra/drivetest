import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> playNavigationFeedback() async {
  try {
    web.window.navigator.vibrate([15.toJS].toJS);
  } catch (_) {
    // Browser does not support vibration or blocked the API.
  }
}
