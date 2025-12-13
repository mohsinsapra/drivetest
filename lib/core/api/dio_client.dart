import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      // Default. Key builder to retrieve requests.
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      // Default. Allows to cache POST requests.
      // Overriding [keyBuilder] is strongly recommended when [true].
      allowPostMethod: false,
    );
    _dio = Dio(BaseOptions(
      // baseUrl: 'http://10.0.2.2:8000/',
      // baseUrl: 'http://192.168.1.130:8010/',
      baseUrl: 'https://taxiexam.hayatpoetry.com/',
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 20000),
    ));
    _dio!.interceptors.add(DioCacheInterceptor(options: options));
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Check if the API is the questions endpoint
        if (response.requestOptions.path.contains('/questions/')) {
          response.data['results'] =
              _decryptQuestions(response.data['results']);
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.response?.data['code'] == 'token_not_valid') {
          final refreshSuccess = await _refreshAccessToken();
          if (refreshSuccess) {
            final requestOptions = error.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $accessToken';
            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
    
    _initialized = true;
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
        data: {
          'refresh': refreshToken,
        },
      );

      accessToken = response.data['access'];

      // If a new refresh token is provided, update and save it
      if (response.data.containsKey('refresh')) {
        refreshToken = response.data['refresh'];
        await _secureStorage.write(key: 'refreshToken', value: refreshToken);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to refresh token: $e');
      return false;
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

    // Remove tokens from both storage locations
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refreshToken');
    await prefs.remove('accessToken');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'accessToken');
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
