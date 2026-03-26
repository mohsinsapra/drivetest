import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';

import 'package:taxi_exam_app/core/utils/crypto_service.dart'; // For HMAC-SHA256 decryption

class DioClient {
  static final DioClient _instance = DioClient._internal();
  DioClient._internal();

  Dio? _dio;
  final keyString = 'ThisIsA32ByteLongSecretKeyForAES'; // 32-byte key
  List<int>? _key;
  // Initialize cipher
  CryptoService? _cryptoService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;

  String? accessToken;
  String? refreshToken;
  Future<bool>? _refreshFuture;
  String? _lastFailedRefreshToken;
  DateTime? _lastFailedRefreshAt;
  String? _last401Fingerprint;
  int _same401Count = 0;
  bool _logoutTriggeredFrom401 = false;

  Dio get dio => _dio!;
  List<int> get key => _key!;
  CryptoService get cryptoService => _cryptoService!;

  factory DioClient() {
    return _instance;
  }

  Future<void> init() async {
    if (_initialized) return; // Prevent multiple initializations
    // Load both tokens from secure storage
    refreshToken = await _secureStorage.read(key: 'refreshToken');
    accessToken = await _secureStorage.read(key: 'accessToken');

    // Fallback to SharedPreferences if not found in secure storage
    if (refreshToken == null || accessToken == null) {
      final prefs = await SharedPreferences.getInstance();
      refreshToken ??= prefs.getString('refreshToken');
      accessToken ??= prefs.getString('accessToken');

      // If found in SharedPreferences, migrate to secure storage
      if (refreshToken != null && accessToken != null) {
        await _secureStorage.write(key: 'refreshToken', value: refreshToken!);
        await _secureStorage.write(key: 'accessToken', value: accessToken!);
      }
    }

    _key = utf8.encode(keyString);
    _cryptoService = CryptoService(Uint8List.fromList(_key!));

    final options = CacheOptions(
      // A default store is required for interceptor.
      store: MemCacheStore(),

      // All subsequent fields are optional.

      // Default.
      policy: CachePolicy.request,
      // Returns a cached response on error but for statuses 401 & 403.
      // Also allows to return a cached response on network errors (e.g. offline usage).
      // Defaults to [null].
      hitCacheOnErrorCodes: [401, 403],
      // Overrides any HTTP directive to delete entry past this duration.
      // Useful only when origin server has no cache config or custom behaviour is desired.
      // Defaults to [null].
      maxStale: const Duration(days: 7),
      // Default. Allows 3 cache sets and ease cleanup.
      priority: CachePriority.normal,
      // Default. Body and headers encryption with your own algorithm.
      cipher: null,
      // Custom key builder: include Authorization header so per-user endpoints
      // (e.g. my-subscriptions) are cached separately per user.
      keyBuilder: ({required Uri url, Map<String, String>? headers}) {
        final auth =
            headers?['Authorization'] ?? headers?['authorization'] ?? '';
        final authHash = auth.isNotEmpty ? auth.hashCode.toRadixString(16) : '';
        final baseKey = CacheOptions.defaultCacheKeyBuilder(url: url);
        return authHash.isNotEmpty ? '${baseKey}_$authHash' : baseKey;
      },
      // Default. Allows to cache POST requests.
      // Overriding [keyBuilder] is strongly recommended when [true].
      allowPostMethod: false,
    );
    _dio = Dio(BaseOptions(
      // baseUrl: 'http://10.0.2.2:8000/',
      baseUrl: 'http://192.168.1.130:8010/',
      // baseUrl: 'https://taxiexam.hayatpoetry.com/',
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 20000),
    ));
    _dio!.interceptors.add(DioCacheInterceptor(options: options));
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final skipAuth = options.extra['skipAuth'] == true;
        if (!skipAuth && accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Any successful response resets repeated-401 tracking.
        _last401Fingerprint = null;
        _same401Count = 0;
        _logoutTriggeredFrom401 = false;

        // Only decrypt legacy questions endpoint (not v2 BCD endpoints)
        final path = response.requestOptions.path;
        if (path.contains('/questions/') && !path.contains('v2/')) {
          response.data['results'] =
              _decryptQuestions(response.data['results']);
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final requestOptions = error.requestOptions;
          final fp = _build401Fingerprint(error);
          if (_last401Fingerprint == fp) {
            _same401Count += 1;
          } else {
            _last401Fingerprint = fp;
            _same401Count = 1;
          }

          if (_same401Count >= 10) {
            if (!_logoutTriggeredFrom401) {
              _logoutTriggeredFrom401 = true;
              await logoutAndRedirect();
            }
            return handler.next(error);
          }

          final skipRefresh = requestOptions.extra['skipRefresh'] == true;
          final isRefreshEndpoint =
              requestOptions.path.contains('api/token/refresh/');

          // Never try to refresh for refresh endpoint itself (prevents loop storm).
          if (skipRefresh || isRefreshEndpoint) {
            await logoutAndRedirect();
            return handler.next(error);
          }

          final responseData = error.response?.data;
          if (responseData is Map &&
              responseData['detail'] ==
                  'You have been logged out because your account was used on another device.') {
            await logoutAndRedirect();
            return handler.resolve(Response(
                requestOptions: error.requestOptions, statusCode: 200));
          } else if (responseData is Map &&
              responseData['code'] == 'token_not_valid') {
            if (_shouldSkipRefreshAttempt()) {
              await logoutAndRedirect();
              return handler.next(error);
            }

            if (requestOptions.extra['__retried__'] == true) {
              await logoutAndRedirect();
              return handler.next(error);
            }

            final refreshSuccess = await _refreshAccessTokenSingleFlight();
            if (refreshSuccess) {
              requestOptions.headers['Authorization'] = 'Bearer $accessToken';
              requestOptions.extra['__retried__'] = true;
              final response = await dio.fetch(requestOptions);
              _last401Fingerprint = null;
              _same401Count = 0;
              _logoutTriggeredFrom401 = false;
              return handler.resolve(response);
            } else {
              await logoutAndRedirect();
            }
          }
        }
        return handler.next(error);
      },
    ));

    _initialized = true;
  }

  Future<void> logoutAndRedirect() async {
    await logout();
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
        (Route<dynamic> route) => false,
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        showAppSnackBar(
          'You have been logged out because your account was used on another device.',
          backgroundColor: Colors.red,
        );
      });
    }
  }

  Future<void> reloadTokens() async {
    // Just reload tokens without full reinitialization
    refreshToken = await _secureStorage.read(key: 'refreshToken');
    accessToken = await _secureStorage.read(key: 'accessToken');

    // Fallback to SharedPreferences if not found in secure storage
    if (refreshToken == null || accessToken == null) {
      final prefs = await SharedPreferences.getInstance();
      refreshToken ??= prefs.getString('refreshToken');
      accessToken ??= prefs.getString('accessToken');
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (refreshToken == null) return false;

    try {
      final response = await dio.post(
        'api/token/refresh/',
        options: Options(
          extra: {
            'skipAuth': true,
            'skipRefresh': true,
          },
        ),
        data: {
          'refresh': refreshToken,
        },
      );

      accessToken = response.data['access'];
      await _secureStorage.write(key: 'accessToken', value: accessToken);
      _lastFailedRefreshToken = null;
      _lastFailedRefreshAt = null;

      // If a new refresh token is provided, update and save it
      if (response.data.containsKey('refresh')) {
        refreshToken = response.data['refresh'];
        await _secureStorage.write(key: 'refreshToken', value: refreshToken);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to refresh token: $e');
      _lastFailedRefreshToken = refreshToken;
      _lastFailedRefreshAt = DateTime.now();

      // Check if token is blacklisted
      if (e is DioException && e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map &&
            responseData['code'] == 'token_not_valid' &&
            responseData['detail'] == 'Token is blacklisted') {
          // Token is blacklisted, logout and redirect to auth page
          await logoutAndRedirect();
        }
      }

      return false;
    }
  }

  bool _shouldSkipRefreshAttempt() {
    if (refreshToken == null) return true;
    if (_lastFailedRefreshToken == null || _lastFailedRefreshAt == null) {
      return false;
    }
    final sameToken = _lastFailedRefreshToken == refreshToken;
    final withinCooldown = DateTime.now().difference(_lastFailedRefreshAt!) <
        const Duration(minutes: 5);
    return sameToken && withinCooldown;
  }

  String _build401Fingerprint(DioException error) {
    final path = error.requestOptions.path;
    final data = error.response?.data;
    if (data is Map) {
      final code = data['code']?.toString() ?? '';
      final detail = data['detail']?.toString() ?? '';
      return '401|$path|$code|$detail';
    }
    return '401|$path|${data?.toString() ?? ''}';
  }

  Future<bool> _refreshAccessTokenSingleFlight() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _refreshAccessToken();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> setTokens(
      {required String access, required String refresh}) async {
    accessToken = access;
    refreshToken = refresh;

    // Save both tokens securely
    await _secureStorage.write(key: 'refreshToken', value: refresh);
    await _secureStorage.write(key: 'accessToken', value: access);
  }

  Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    _initialized =
        false; // Force full re-init on next login (fresh Dio + cache)

    // Wipe all secure storage
    await _secureStorage.deleteAll();

    // Remove tokens from SharedPreferences (rest is cleared by the caller)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refreshToken');
    await prefs.remove('accessToken');
  }

  List<Question> _decryptQuestions(List<dynamic> data) {
    return data.map((questionMap) {
      // Decrypt question fields
      final decryptedQuestion = Question(
        text: _decryptField(questionMap['text'] ?? ''),
        imageUrl: _decryptField(questionMap['image_url'] ?? ''),
        correctAnswer: questionMap['correct_answer'] ?? '',
        answerExplanation:
            _decryptField(questionMap['answer_explanation'] ?? ''),
        questionId: questionMap['question_id']?.toString() ?? '',
        options: (questionMap['options'] as List<dynamic>).map((optionMap) {
          return Option(
            optionLabel: optionMap['option_label'] ?? '',
            text: _decryptField(optionMap['text'] ?? ''),
            imageUrl: _decryptField(optionMap['image_url'] ?? ''),
          );
        }).toList(),
      );

      return decryptedQuestion;
    }).toList();
  }

  String _decryptField(String? field) {
    if (field == null || field.isEmpty) return field ?? '';

    return cryptoService.decrypt(field);
  }
}
