import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';

// Paste your VAPID key from Firebase Console →
// Project Settings → Cloud Messaging → Web configuration → Key pair
const _webVapidKey =
    'BO08sXwRIqAQU5FPLThK2rB2ti66imtY6oqsikvEP_2txuKE6k-AhO6zLdgHFXD__5jvGfCK5SlpLeMFD4SJEYQ';

class NotificationPayload {
  const NotificationPayload({
    required this.title,
    required this.body,
    required this.type,
  });

  final String title;
  final String body;
  final String type;

  bool get hasVisibleContent => title.isNotEmpty || body.isNotEmpty;
}

NotificationPayload notificationPayloadFromRaw({
  String? title,
  String? body,
  Map<String, dynamic> data = const {},
}) {
  final resolvedTitle = (title?.trim().isNotEmpty == true)
      ? title!.trim()
      : (data['title']?.toString().trim() ?? '');
  final resolvedBody = (body?.trim().isNotEmpty == true)
      ? body!.trim()
      : (data['body']?.toString().trim() ?? '');
  final resolvedType = (data['type']?.toString().trim().isNotEmpty == true)
      ? data['type'].toString().trim()
      : 'general';

  return NotificationPayload(
    title: resolvedTitle,
    body: resolvedBody,
    type: resolvedType,
  );
}

NotificationPayload _payloadFromMessage(RemoteMessage message) {
  return notificationPayloadFromRaw(
    title: message.notification?.title,
    body: message.notification?.body,
    data: Map<String, dynamic>.from(message.data),
  );
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(LocalNotificationAdapter());
  }

  final payload = _payloadFromMessage(message);
  if (!payload.hasVisibleContent) return;

  final provider = await NotificationProvider.ensureInitialized();
  await provider.add(payload.title, payload.body, type: payload.type);
  debugPrint('[FCM] stored background message: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;
  static bool _backgroundHandlerRegistered = false;
  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onOpenedSub;

  /// Call once after Firebase.initializeApp and after the user is authenticated.
  static Future<void> init(ApiService api) async {
    if (!_backgroundHandlerRegistered) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _backgroundHandlerRegistered = true;
    }

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
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

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
      final payload = _payloadFromMessage(message);
      if (payload.hasVisibleContent) {
        try {
          await NotificationProvider.instance.add(
            payload.title,
            payload.body,
            type: payload.type,
          );
        } catch (e) {
          debugPrint('[FCM] failed to persist notification: $e');
        }
        final snackText =
            [payload.title, payload.body].where((s) => s.isNotEmpty).join(': ');
        showAppSnackBar(
          snackText,
          type: _toastStyle(payload.type),
          icon: _toastIcon(payload.type),
        );
      }
    });

    // Background tap — app was in background, user tapped notification
    _onOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] opened from background: ${message.messageId}');
      // Future: navigate based on message.data['screen']
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final payload = _payloadFromMessage(initialMessage);
      if (payload.hasVisibleContent) {
        try {
          await NotificationProvider.instance.add(
            payload.title,
            payload.body,
            type: payload.type,
          );
        } catch (e) {
          debugPrint('[FCM] failed to persist launch notification: $e');
        }
      }
      debugPrint('[FCM] opened from terminated: ${initialMessage.messageId}');
    }

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
