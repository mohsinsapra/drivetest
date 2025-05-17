import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:taxi_exam_app/core/utils/crypto_service.dart'; // For HMAC-SHA256 decryption

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;
  final keyString = 'ThisIsA32ByteLongSecretKeyForAES'; // 32-byte key
  late final List<int> key;
  // Initialize cipher
  late final CryptoService cryptoService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? accessToken;
  String? refreshToken;
  factory DioClient() {
    return _instance;
  }
  Future<void> init() async {
    // Load the refreshToken from secure storage
    refreshToken = await _secureStorage.read(key: 'refreshToken');
  }

  DioClient._internal() {
    key = utf8.encode(keyString);
    cryptoService = CryptoService(Uint8List.fromList(key));

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
    dio = Dio(BaseOptions(
      // baseUrl: 'http://10.0.2.2:8000/',
      // baseUrl: 'http://192.168.1.84:8000/',
      baseUrl: 'https://taxiexam.hayatpoetry.com/',
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 20000),
    ));
    dio.interceptors.add(DioCacheInterceptor(options: options));
    dio.interceptors.add(InterceptorsWrapper(
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
      print('Failed to refresh token: $e');
      return false;
    }
  }

  Future<void> setTokens(
      {required String access, required String refresh}) async {
    accessToken = access;
    refreshToken = refresh;

    // Save the refreshToken securely
    await _secureStorage.write(key: 'refreshToken', value: refresh);
  }

  Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    await _secureStorage.delete(key: 'refreshToken');
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
