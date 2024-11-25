import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';

import 'package:taxi_exam_app/core/utils/crypto_service.dart'; // For HMAC-SHA256 decryption

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;
  final keyString = 'ThisIsA32ByteLongSecretKeyForAES'; // 32-byte key
  late final List<int> key;
  // Initialize cipher
  late final CryptoService cryptoService;

  String? accessToken;
  String? refreshToken;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    key = utf8.encode(keyString);
    cryptoService = CryptoService(Uint8List.fromList(key));

    dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8000/',
      // baseUrl: 'http://192.168.1.79:8000/api/',
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 3000),
    ));

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
        'token/refresh/',
        data: {
          'refresh': refreshToken,
        },
      );

      accessToken = response.data['access'];
      return true;
    } catch (e) {
      print('Failed to refresh token: $e');
      return false;
    }
  }

  // List<Question> _decryptQuestions(List<dynamic> data) {
  //   return data.map((questionMap) {
  //     return Question.fromMap(questionMap, _decryptField);
  //   }).toList();
  // }

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
