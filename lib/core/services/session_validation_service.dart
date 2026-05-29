import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';

typedef FetchCurrentUser = Future<void> Function();
typedef IsAuthenticated = bool Function();
typedef NowProvider = DateTime Function();

class SessionValidationService {
  SessionValidationService({
    required this.isAuthenticated,
    required this.fetchCurrentUser,
    this.now = DateTime.now,
    this.minInterval = const Duration(minutes: 3),
  });

  final IsAuthenticated isAuthenticated;
  final FetchCurrentUser fetchCurrentUser;
  final NowProvider now;
  final Duration minInterval;

  DateTime? _lastValidationAt;
  Future<void>? _inFlightValidation;
  Timer? _pollingTimer;

  void startForegroundPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(minInterval, (_) {
      validateIfNeeded();
    });
  }

  void stopForegroundPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void dispose() {
    stopForegroundPolling();
  }

  Future<void> onAppResumed() => validateIfNeeded();

  Future<void> validateIfNeeded({bool force = false}) async {
    if (!isAuthenticated()) return;
    if (_inFlightValidation != null) {
      await _inFlightValidation;
      return;
    }

    final lastValidationAt = _lastValidationAt;
    final intervalElapsed = lastValidationAt == null ||
        now().difference(lastValidationAt) >= minInterval;
    if (!force && !intervalElapsed) return;

    _inFlightValidation = _runValidation();
    try {
      await _inFlightValidation;
    } finally {
      _inFlightValidation = null;
    }
  }

  Future<void> _runValidation() async {
    try {
      await fetchCurrentUser();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // This service only validates `/self`, so a 401/403 here means
      // the active session is no longer valid and we must leave dashboard.
      if (status == 401 || status == 403) {
        await DioClient().logoutAndRedirect();
      }
      return;
    } catch (_) {
      // Network/timeout errors are transient — keep the session alive.
      return;
    }
    _lastValidationAt = now();
  }
}

class SessionValidationLifecycleObserver with WidgetsBindingObserver {
  SessionValidationLifecycleObserver(this._service);

  final SessionValidationService _service;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    _service.startForegroundPolling();
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _service.onAppResumed();
    }
  }
}
