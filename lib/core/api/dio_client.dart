import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'certificate_pinning_stub.dart'
    if (dart.library.io) 'certificate_pinning_io.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/services/user_cache_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';

import 'package:taxi_exam_app/core/utils/crypto_service.dart';
import 'package:taxi_exam_app/config/local_config.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';

enum LogoutReason { sessionExpired, signedInElsewhere }

class DioClient {
  static final DioClient _instance = DioClient._internal();
  DioClient._internal();

  Dio? _dio;
  MemCacheStore? _cacheStore;
  final keyString = 'ThisIsA32ByteLongSecretKeyForAES'; // 32-byte key
  List<int>? _key;
  // Initialize cipher
  CryptoService? _cryptoService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  bool _initialized = false;

  String? accessToken;
  String? refreshToken;
  Future<bool>? _refreshFuture;
  String? _lastFailedRefreshToken;
  DateTime? _lastFailedRefreshAt;
  String? _last401Fingerprint;
  int _same401Count = 0;
  bool _logoutTriggeredFrom401 = false;
  bool _logoutInProgress = false;

  Dio get dio => _dio!;

  /// Clears all in-memory HTTP cached responses.
  /// Call after actions that change server-side state (e.g. subscription purchase)
  /// so the next request fetches fresh data instead of a stale cached response.
  Future<void> clearCache() async {
    await _cacheStore?.clean();
  }

  Options cacheOptions({required CachePolicy policy}) {
    return CacheOptions(
      store: _cacheStore!,
      policy: policy,
    ).toOptions();
  }

  List<int> get key => _key!;
  CryptoService get cryptoService => _cryptoService!;

  factory DioClient() {
    return _instance;
  }

  Future<void> init() async {
    if (_initialized) return; // Prevent multiple initializations
    // Load both tokens from secure storage.
    // Wrapped in try/catch because flutter_secure_storage on iOS web can throw
    // (Web Crypto API failures) instead of returning null, which would prevent
    // the SharedPreferences fallback from ever running.
    try {
      refreshToken = await _secureStorage.read(key: 'refreshToken');
      accessToken = await _secureStorage.read(key: 'accessToken');
    } catch (e) {
      debugPrint('[DioClient] secure storage read failed (non-fatal): $e');
      refreshToken = null;
      accessToken = null;
    }

    // Fallback to SharedPreferences if not found in secure storage
    if (refreshToken == null || accessToken == null) {
      // If found in SharedPreferences, migrate to secure storage
      if (refreshToken != null && accessToken != null) {
        try {
          await _secureStorage.write(key: 'refreshToken', value: refreshToken!);
          await _secureStorage.write(key: 'accessToken', value: accessToken!);
        } catch (e) {
          debugPrint(
              '[DioClient] secure storage migration write failed (non-fatal): $e');
        }
      }
    }

    // Scope Hive boxes to the returning user before any box is opened.
    if (accessToken != null) {
      final userId = _userIdFromJwt(accessToken!);
      if (userId != null) AppStorage.setCurrentUser(userId);
    }

    _key = utf8.encode(keyString);
    _cryptoService = CryptoService(Uint8List.fromList(_key!));

    _cacheStore = MemCacheStore();
    final options = CacheOptions(
      // A default store is required for interceptor.
      store: _cacheStore,

      // All subsequent fields are optional.

      // Default.
      policy: CachePolicy.request,
      // Never serve cached data for auth failures. If the backend returns
      // 401/403 we must surface it so refresh/logout+redirect can run.
      // Keeping these out prevents "logged out but still on dashboard" states.
      hitCacheOnErrorCodes: const [],
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
      keyBuilder: (
          {required Uri url, Map<String, String>? headers, Object? body}) {
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
    const tunnelUrl = String.fromEnvironment('API_BASE_URL');
    final baseUrl = tunnelUrl.isNotEmpty
        ? tunnelUrl
        : kReleaseMode
            ? 'https://taxiexam.hayatpoetry.com/'
            : kLocalDevBaseUrl;

    _dio = Dio(BaseOptions(
      // baseUrl: 'http://10.0.2.2:8000/',
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 20000),
    ));

    // Certificate pinning — skipped in debug so local dev server still works.
    // On web this is a no-op; the browser enforces its own cert validation.
    if (kReleaseMode) {
      await applyPinning(_dio!);
    }

    // Auth/error interceptor runs FIRST so the Authorization header is set
    // before the cache interceptor builds its key. This ensures each user's
    // responses are cached under a unique key (URL + auth hash) and that 401s
    // trigger a token refresh before the cache's hitCacheOnErrorCodes fallback
    // can serve another user's stale response.
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

        final path = response.requestOptions.path;

        // Decrypt v2 BCD encrypted+compressed responses  { "data": "<base64>" }
        // Only present in production — dev returns plain JSON directly
        if (path.contains('api/v2/') &&
            response.data is Map &&
            response.data['data'] is String) {
          try {
            final decrypted = cryptoService
                .decryptCompressed(response.data['data'] as String);
            response.data = jsonDecode(decrypted);
          } catch (e, stack) {
            debugPrint('[Decrypt] ERROR on $path: $e');
            debugPrint('[Decrypt] $stack');
          }
        }

        // Decrypt legacy questions endpoint (not v2 BCD endpoints)
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
            await logoutAndRedirect(
              reason: LogoutReason.signedInElsewhere,
            );
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
        // Connection/receive/send timeout
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          showAppSnackBar(
            t.error_connection_timeout,
            type: SnackBarType.error,
          );
          return handler.next(error);
        }

        // 429 — rate limited / throttled
        if (error.response?.statusCode == 429) {
          final retryAfterRaw =
              error.response?.headers.value('retry-after') ?? '';
          final retrySeconds = int.tryParse(retryAfterRaw) ?? 60;
          final waitMsg = retrySeconds >= 60
              ? '${(retrySeconds / 60).ceil()} min'
              : '$retrySeconds s';
          showAppSnackBar(
            t.error_too_many_requests.replaceAll('{wait}', waitMsg),
            type: SnackBarType.error,
          );
          return handler.next(error);
        }

        // 503 — server temporarily unavailable (e.g. Google auth timeout)
        if (error.response?.statusCode == 503) {
          showAppSnackBar(
            t.error_service_unavailable,
            type: SnackBarType.error,
          );
          return handler.next(error);
        }

        return handler.next(error);
      },
    ));

    // Sentry and cache run AFTER the auth interceptor so the Authorization
    // header is already set when the cache key is built.
    _dio!.addSentry(captureFailedRequests: true);
    _dio!.interceptors.add(DioCacheInterceptor(options: options));

    _initialized = true;
  }

  Future<void> logoutAndRedirect({
    LogoutReason reason = LogoutReason.sessionExpired,
  }) async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    try {
      await logout();
      await UserCacheService.clearAll();
      final navigator = NavigationService.navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          AppQuickFadeRoute(builder: (context) => const AuthScreen()),
          (Route<dynamic> route) => false,
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          final message = reason == LogoutReason.signedInElsewhere
              ? t.error_logged_out_other_device
              : t.error_session_expired;
          showAppSnackBar(
            message,
            type: SnackBarType.error,
          );
        });
      }
    } finally {
      _logoutInProgress = false;
    }
  }

  Future<void> reloadTokens() async {
    // Just reload tokens without full reinitialization.
    // Wrapped in try/catch: flutter_secure_storage on iOS web can throw
    // instead of returning null, bypassing the SharedPreferences fallback.
    try {
      refreshToken = await _secureStorage.read(key: 'refreshToken');
      accessToken = await _secureStorage.read(key: 'accessToken');
    } catch (e) {
      debugPrint('[DioClient] secure storage read failed (non-fatal): $e');
      refreshToken = null;
      accessToken = null;
    }

    // Fallback to SharedPreferences if not found in secure storage
    if (refreshToken == null || accessToken == null) {}
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
      try {
        await _secureStorage.write(key: 'accessToken', value: accessToken);
      } catch (e) {
        debugPrint(
            '[DioClient] secure storage write (access) failed (non-fatal): $e');
      }
      _lastFailedRefreshToken = null;
      _lastFailedRefreshAt = null;

      // Mirror to SharedPreferences for iOS web browser resilience.

      // If a new refresh token is provided, update and save it
      if (response.data.containsKey('refresh')) {
        refreshToken = response.data['refresh'];
        try {
          await _secureStorage.write(key: 'refreshToken', value: refreshToken);
        } catch (e) {
          debugPrint(
              '[DioClient] secure storage write (refresh) failed (non-fatal): $e');
        }
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

  /// Extracts the `user_id` claim from a JWT access token without a network
  /// call. Returns null if the token is malformed or the claim is absent.
  static String? _userIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map;
      return payload['user_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> setTokens(
      {required String access, required String refresh}) async {
    accessToken = access;
    refreshToken = refresh;

    // Scope Hive boxes to this user before any box is opened.
    final userId = _userIdFromJwt(access);
    if (userId != null) AppStorage.setCurrentUser(userId);

    // Save both tokens securely.
    // Wrapped in try/catch: on iOS web flutter_secure_storage can throw,
    // which would prevent the SharedPreferences write below from executing.
    try {
      await _secureStorage.write(key: 'refreshToken', value: refresh);
      await _secureStorage.write(key: 'accessToken', value: access);
    } catch (e) {
      debugPrint('[DioClient] secure storage write failed (non-fatal): $e');
    }

    // Always persist to SharedPreferences so iOS web browsers can reliably
    // recover tokens across sessions. flutter_secure_storage on iOS Safari
    // can lose its AES decryption key between sessions, causing read() to
    // return null and leaving the user logged out on reload.
  }

  Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    _initialized =
        false; // Force full re-init on next login (fresh Dio + cache)

    // Purge every cached HTTP response so the next user cannot receive another
    // user's data from the in-memory cache store.
    await _cacheStore?.clean();

    // Wipe all secure storage
    await _secureStorage.deleteAll();

    // User scope is reset in AppStorage.clearUserData() which is called after this.
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
