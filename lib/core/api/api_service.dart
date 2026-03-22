import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'dio_client.dart';

class ApiService {
  final Dio _dio = DioClient().dio;
  final DioClient _dioClient = DioClient();

  Future<void> authenticate(String username, String password) async {
    try {
      final response = await _dio.post(
        'api/token/',
        data: {
          'username': username,
          'password': password,
        },
      );

      // Use setTokens method to properly save both tokens
      await _dioClient.setTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _dioClient.logout();

    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  Future<dynamic> fetchCurrentUser() async {
    try {
      final response = await _dio.get('api/user/self/');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch current user: $e');
    }
  }

  Future<dynamic> signup(String email, String username, String password) async {
    try {
      final response = await _dio.post(
        'api/user/signup/',
        data: {
          'username': username,
          'password': password,
          'email': email,
        },
      );

      return response;
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  Future<List<dynamic>> fetchLicenses() async {
    try {
      final response = await _dio.get('api/licences/');
      // Ensure the response data has the expected structure and extract results
      if (response.data != null && response.data is Map<String, dynamic>) {
        return response.data['results'] as List<dynamic>;
      } else {
        throw Exception('Unexpected response format: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to fetch licenses: $e');
    }
  }

  Future<List<dynamic>> fetchCategories(String licenceTypeId) async {
    final response = await _dio.get(
      'api/licences/$licenceTypeId/',
    );
    return response.data['categories'];
  }

  Future<List<Question>> fetchQuestions(String licenceId, String categoryId,
      {int pageSize = 20, bool randomize = false}) async {
    final params = <String, dynamic>{
      'page_size': pageSize,
      'randomize': randomize,
    };
    // Bust the cache for randomized requests so each fetch returns a fresh shuffle.
    if (randomize) {
      params['_t'] = DateTime.now().millisecondsSinceEpoch;
    }
    final response = await _dio.get(
        'api/licences/$licenceId/categories/$categoryId/questions/',
        queryParameters: params);

    return response.data['results'];
  }

  String fetchImage(
      String licenceId, String categoryId, String imagePath)  {
    final imageUrl =
        '${_dio.options.baseUrl}secure-media/$licenceId/$categoryId/$imagePath/';

    return imageUrl;
  }

  Future<String> createPaymentIntent(int amount, String paymentMethod,
      String licenceId, String categoryId) async {
    try {
      final response = await _dio.post(
        'api/payment/create-intent/',
        data: {
          // 'amount': amount, // Amount in cents (e.g., 5000 = $50.00)
          // 'currency': 'sek',
          // 'payment_method_types': [paymentMethod],
          'licence_id': licenceId,
          'category_id': categoryId, // Specify selected method
        },
      );

      return response.data['clientSecret']; // Return the client secret
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  /// Push one attempt to the backend (fire-and-forget — never throws).
  /// Only stores IDs and selections — not full question data.
  Future<void> syncTestAttempt(TestAttempt attempt) async {
    try {
      final selections =
          attempt.userSelections.map((k, v) => MapEntry(k.toString(), v));
      final questionIds =
          attempt.questions.map((q) => q.questionId).toList();

      await _dio.post('api/user/test-attempts/', data: {
        'attempt_id': attempt.testId,
        'licence_id': attempt.licenceId ?? '',
        'category_id': attempt.categoryId ?? '',
        'date_time': attempt.dateTime.toUtc().toIso8601String(),
        'score': attempt.score,
        'has_passed': attempt.hasPassed,
        'status': attempt.status,
        'current_question_index': attempt.currentQuestionIndex,
        'user_selections': selections,
        'question_ids': questionIds,
      });
    } catch (e) {
      debugPrint('[syncTestAttempt] backend sync failed: $e');
      // Local Hive is the primary store — backend sync is best-effort
    }
  }

  /// Fetch all attempts for the current user from the backend.
  /// Returns an empty list on any error (offline-safe).
  Future<List<Map<String, dynamic>>> fetchTestAttempts() async {
    try {
      // Cache-bust so we never get a stale cached list
      final response = await _dio.get(
        'api/user/test-attempts/',
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
      );
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['results'] is List) {
        return (data['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('[fetchTestAttempts] failed: $e');
      return [];
    }
  }

  /// Fetch the exact questions for a saved attempt using only its [attemptId].
  /// The backend looks up its own stored question_ids and returns them in order.
  /// Returns empty list on any error (offline-safe).
  Future<List<Question>> fetchQuestionsForAttempt(String attemptId) async {
    try {
      final response = await _dio.post(
        'api/questions/for-attempt/',
        data: {'attempt_id': attemptId},
      );
      final results = response.data['results'];
      if (results is List) return results.cast<Question>();
      return [];
    } catch (e) {
      debugPrint('[fetchQuestionsForAttempt] failed: $e');
      return [];
    }
  }

  /// Convert a backend JSON map into a [TestAttempt] for local Hive storage.
  /// Pass [questions] if you have already fetched them; otherwise they'll be empty.
  TestAttempt? testAttemptFromJson(Map<String, dynamic> data,
      {List<Question> questions = const []}) {
    try {
      final selectionsJson =
          (data['user_selections'] as Map<String, dynamic>? ?? {});
      final selections = selectionsJson
          .map((k, v) => MapEntry(int.tryParse(k) ?? 0, v.toString()));

      return TestAttempt(
        testId: data['attempt_id'] as String,
        dateTime: DateTime.parse(data['date_time'] as String).toLocal(),
        userSelections: selections,
        score: (data['score'] as num?)?.toDouble() ?? 0,
        hasPassed: data['has_passed'] as bool? ?? false,
        questions: questions,
        licenceName: data['licence_name'] as String?,
        categoryName: data['category_name'] as String?,
        status: data['status'] as String? ?? 'completed',
        currentQuestionIndex: data['current_question_index'] as int? ?? 0,
        licenceId: data['licence_id'] as String?,
        categoryId: data['category_id'] as String?,
      );
    } catch (e) {
      debugPrint('[testAttemptFromJson] parse error: $e');
      return null;
    }
  }

  Future<void> googleAuth({String? idToken, String? accessToken}) async {
    try {
      final data = idToken != null
          ? {'id_token': idToken}
          : {'access_token': accessToken};
      final response = await _dio.post('api/user/google-auth/', data: data);
      await _dioClient.setTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
    } catch (e) {
      throw Exception('Google authentication failed: $e');
    }
  }

  /// Delete a single attempt from the backend. Returns true on success.
  Future<bool> deleteTestAttempt(String attemptId) async {
    try {
      await _dio.delete('api/user/test-attempts/$attemptId/');
      return true;
    } catch (e) {
      debugPrint('[deleteTestAttempt] failed: $e');
      return false;
    }
  }

  /// Delete all attempts for the current user from the backend.
  Future<void> deleteAllTestAttempts() async {
    try {
      final attempts = await fetchTestAttempts();
      for (final a in attempts) {
        final id = a['attempt_id'] as String? ?? '';
        if (id.isNotEmpty) await _dio.delete('api/user/test-attempts/$id/');
      }
    } catch (e) {
      debugPrint('[deleteAllTestAttempts] failed: $e');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post(
        'api/user/password-reset/',
        data: {
          'email': email,
        },
      );
    } catch (e) {
      throw Exception('Failed to request password reset: $e');
    }
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        'api/user/password-reset/confirm/',
        data: {
          'email': email,
          'token': token,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }
}
