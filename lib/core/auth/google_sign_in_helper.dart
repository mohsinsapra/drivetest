import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInHelper {
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static GoogleSignIn create() {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId: _webClientId.isEmpty ? null : _webClientId,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return GoogleSignIn(
          serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return GoogleSignIn(
          clientId: _webClientId.isEmpty ? null : _webClientId,
          serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
        );
      default:
        return GoogleSignIn();
    }
  }

  static String userMessage(Object error) {
    if (error is PlatformException &&
        error.code == 'sign_in_failed' &&
        error.message?.contains('ApiException: 10') == true) {
      return 'Google sign-in is misconfigured for Android. Check the Firebase app package, SHA-1/SHA-256 fingerprints, and OAuth client IDs.';
    }

    return 'Google sign-in failed. Please try again.';
  }
}
