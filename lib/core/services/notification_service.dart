import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';

// Paste your VAPID key from Firebase Console →
// Project Settings → Cloud Messaging → Web configuration → Key pair
const _webVapidKey =
    'BO08sXwRIqAQU5FPLThK2rB2ti66imtY6oqsikvEP_2txuKE6k-AhO6zLdgHFXD__5jvGfCK5SlpLeMFD4SJEYQ';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;
  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onOpenedSub;

  /// Call once after Firebase.initializeApp and after the user is authenticated.
  static Future<void> init(ApiService api) async {
    if (_isInitialized) {
      // App session may survive logout/login without reattaching listeners.
      // Re-register token so backend always has the current active device.
      await _registerToken(api);
      return;
    }

    debugPrint('[FCM] init() called, platform=$_platform');

    // Request permission (iOS + Android 13+; web prompts browser dialog)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission status: ${settings.authorizationStatus}');

    // Register current token
    await _registerToken(api);

    // Re-register whenever the token rotates
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      try {
        await api.registerFCMToken(newToken, _platform);
      } catch (e) {
        debugPrint('[FCM] token refresh registration failed: $e');
      }
    });

    // Foreground messages — store locally and show snackbar
    _onMessageSub =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      final type = (message.data['type'] ?? 'general').toString();
      if (title.isNotEmpty || body.isNotEmpty) {
        try {
          await NotificationProvider.instance.add(title, body, type: type);
        } catch (e) {
          debugPrint('[FCM] failed to persist notification: $e');
        }
        showAppSnackBar(
          '$title: $body',
          type: _toastStyle(type),
          icon: _toastIcon(type),
        );
      }
    });

    // Background tap — app was in background, user tapped notification
    _onOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] opened from background: ${message.messageId}');
      // Future: navigate based on message.data['screen']
    });

    _isInitialized = true;
  }

  /// Call during logout to stop receiving notifications on this device.
  static Future<void> deregister(ApiService api) async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
      if (token != null) {
        await api.deregisterFCMToken(token);
        await _messaging.deleteToken();
      }

      await _tokenRefreshSub?.cancel();
      await _onMessageSub?.cancel();
      await _onOpenedSub?.cancel();
      _tokenRefreshSub = null;
      _onMessageSub = null;
      _onOpenedSub = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('[FCM] deregister failed (non-fatal): $e');
    }
  }

  static Future<void> _registerToken(ApiService api) async {
    try {
      debugPrint('[FCM] calling getToken()...');
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
      debugPrint(
          '[FCM] token=${token == null ? "NULL" : "${token.substring(0, 20)}..."}');
      if (token != null) {
        await api.registerFCMToken(token, _platform);
        debugPrint('[FCM] token registered with backend');
      } else {
        debugPrint('[FCM] token was null — check VAPID key or service worker');
      }
    } catch (e) {
      debugPrint('[FCM] token registration failed: $e');
    }
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    // defaultTargetPlatform is safe on all platforms including web
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  static SnackBarType _toastStyle(String type) {
    switch (type) {
      case 'subscription':
      case 'app_update':
      case 'payment':
        return SnackBarType.success;
      case 'warning':
        return SnackBarType.error;
      default:
        return SnackBarType.info;
    }
  }

  static IconData _toastIcon(String type) {
    switch (type) {
      case 'subscription':
        return Icons.card_membership_rounded;
      case 'app_update':
        return Icons.system_update_alt_rounded;
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
