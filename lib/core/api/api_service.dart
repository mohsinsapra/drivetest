import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/notification_service.dart';
import 'package:taxi_exam_app/core/services/user_cache_service.dart';
import 'dio_client.dart';

class ApiService {
  final Dio _dio = DioClient().dio;
  final DioClient _dioClient = DioClient();

  Future<bool> authenticate(String username, String password) async {
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
      return response.data['is_first_login'] == true;
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  Future<void> logout() async {
    // Deregister FCM token and reset NotificationService state before clearing credentials
    try {
      await NotificationService.deregister(this);
    } catch (e) {
      debugPrint('FCM deregister on logout failed (non-fatal): $e');
    }
    final refreshToken = _dioClient.refreshToken;
    // Best-effort: blacklist the refresh token on the server
    if (refreshToken != null) {
      try {
        await _dio.post(
          'api/user/logout/',
          data: {'refresh': refreshToken},
        );
      } catch (e) {
        debugPrint('Server logout error (non-fatal): $e');
      }
    }
    // Always clear local tokens regardless of server response
    try {
      await _dioClient.logout();
    } catch (e) {
      debugPrint('Local logout error (non-fatal): $e');
    }
    // Wipe all user-specific cached data (BcdCache, Hive boxes).
    await UserCacheService.clearAll();
  }

  Future<dynamic> fetchCurrentUser() async {
    try {
      final response = await _dio.get('api/user/self/');
      final data = response.data;
      // Seed BcdCache from the embedded dashboard tree so subsequent
      // BcdCache.ensureLoaded() calls skip all individual category/test fetches.
      if (data is Map<String, dynamic>) {
        final dashboard = data['bcd_dashboard'];
        if (dashboard is List) {
          BcdCache.instance.seedFromSelfResponse(dashboard);
        }
      }
      return data;
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

  String fetchImage(String licenceId, String categoryId, String imagePath) {
    // BCD images are already full URLs — return them directly
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return '${_dio.options.baseUrl}secure-media/$licenceId/$categoryId/$imagePath/';
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
      final questionIds = attempt.questions.map((q) => q.questionId).toList();

      await _dio.post('api/user/test-attempts/', data: {
        'bcd_test_id': attempt.bcdCategoryId != null
            ? int.tryParse(attempt.categoryId ?? '')
            : null,
        'attempt_id': attempt.testId,
        'licence_id': attempt.licenceId ?? '',
        'licence_name': attempt.licenceName ?? '',
        'category_id': attempt.categoryId ?? '',
        'category_name': attempt.categoryName ?? '',
        'bcd_category_id': attempt.bcdCategoryId,
        'bcd_category_name': attempt.categoryName ?? '',
        'date_time': attempt.dateTime.toUtc().toIso8601String(),
        'score': attempt.score,
        'has_passed': attempt.hasPassed,
        'status': attempt.status,
        'current_question_index': attempt.currentQuestionIndex,
        'user_selections': selections,
        'question_ids': questionIds,
        'duration_seconds': attempt.durationSeconds ?? 0,
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

  /// Fetch aggregated progress per legacy category and BCD category.
  Future<List<Map<String, dynamic>>> fetchUserProgress() async {
    try {
      final response = await _dio.get(
        'api/user/progress/',
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
      );
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['results'] is List) {
        return (data['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('[fetchUserProgress] failed: $e');
      return [];
    }
  }

  Future<bool> submitQuestionFeedback({
    required String questionId,
    required String questionText,
    required String feedbackText,
    required String scopeType,
    String feedbackType = 'question_issue',
    String? licenceId,
    String? categoryId,
    int? bcdCategoryId,
    int? bcdTestId,
    String? licenceName,
    String? categoryName,
  }) async {
    try {
      await _dio.post('api/user/question-feedback/', data: {
        'question_id': questionId,
        'question_text': questionText,
        'feedback_text': feedbackText,
        'scope_type': scopeType,
        'feedback_type': feedbackType,
        'licence_id': licenceId ?? '',
        'category_id': categoryId ?? '',
        'bcd_category_id': bcdCategoryId,
        'bcd_test_id': bcdTestId,
        'licence_name': licenceName ?? '',
        'category_name': categoryName ?? '',
      });
      return true;
    } catch (e) {
      debugPrint('[submitQuestionFeedback] failed: $e');
      return false;
    }
  }

  Future<bool> submitAppFeedback({
    required String message,
    String subject = '',
    String screenContext = '',
    String feedbackType = 'app_issue',
    String contactEmail = '',
  }) async {
    try {
      await _dio.post('api/user/app-feedback/', data: {
        'message': message,
        'subject': subject,
        'screen_context': screenContext,
        'feedback_type': feedbackType,
        'contact_email': contactEmail,
      });
      return true;
    } catch (e) {
      debugPrint('[submitAppFeedback] failed: $e');
      return false;
    }
  }

  Future<Set<String>> fetchSavedQuestionIds({
    required String scopeType,
    String? licenceId,
    String? categoryId,
    int? bcdCategoryId,
  }) async {
    try {
      final response = await _dio.get(
        'api/user/saved-questions/',
        queryParameters: {
          'scope_type': scopeType,
          'licence_id': licenceId ?? '',
          'category_id': categoryId ?? '',
          'bcd_category_id': bcdCategoryId,
        },
      );
      final data = response.data;
      final list = data is List
          ? data
          : (data is Map && data['results'] is List)
              ? data['results'] as List
              : <dynamic>[];
      return list
          .map((e) =>
              (e as Map<String, dynamic>)['question_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('[fetchSavedQuestionIds] failed: $e');
      return <String>{};
    }
  }

  Future<List<Question>> fetchSavedQuestionsResolved({
    required String scopeType,
    String? licenceId,
    String? categoryId,
    int? bcdCategoryId,
  }) async {
    try {
      final response = await _dio.get(
        'api/user/saved-questions/resolved-questions/',
        queryParameters: {
          'scope_type': scopeType,
          'licence_id': licenceId ?? '',
          'category_id': categoryId ?? '',
          'bcd_category_id': bcdCategoryId,
        },
      );
      final data = response.data;
      final list = data is List
          ? data
          : (data is Map && data['results'] is List)
              ? data['results'] as List
              : <dynamic>[];

      return list.map((raw) {
        final m = raw as Map<String, dynamic>;
        final options = (m['options'] as List<dynamic>? ?? []).map((o) {
          final map = Map<String, dynamic>.from(o as Map<String, dynamic>);
          map['text'] = _cleanSavedText((map['text'] ?? '').toString());
          return Option.fromMap(map);
        }).toList();
        final isBcd = m['is_bcd'] == true;
        final rawImage = (m['image_url'] ?? '').toString();
        final image = isBcd &&
                rawImage.isNotEmpty &&
                !rawImage.startsWith('http://') &&
                !rawImage.startsWith('https://')
            ? bcdMediaUrl(rawImage)
            : rawImage;
        return Question(
          questionId: (m['question_id'] ?? '').toString(),
          text: _cleanSavedText((m['text'] ?? '').toString()),
          imageUrl: image,
          correctAnswer: (m['correct_answer'] ?? '').toString(),
          answerExplanation:
              _cleanSavedText((m['answer_explanation'] ?? '').toString()),
          options: options,
        );
      }).toList();
    } catch (e) {
      debugPrint('[fetchSavedQuestionsResolved] failed: $e');
      return [];
    }
  }

  String _cleanSavedText(String raw) {
    var text = raw;
    if (text.codeUnits.isNotEmpty && text.codeUnits.every((c) => c < 256)) {
      try {
        text = utf8.decode(text.codeUnits.toList());
      } catch (_) {}
    }
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll('\\n', '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&auml;', 'ä')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&aring;', 'å')
        .replaceAll('&Auml;', 'Ä')
        .replaceAll('&Ouml;', 'Ö')
        .replaceAll('&Aring;', 'Å')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&egrave;', 'è')
        .replaceAll('&uuml;', 'ü')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }

  Future<bool?> toggleSavedQuestion({
    required String questionId,
    required String scopeType,
    String? licenceId,
    String? categoryId,
    int? bcdCategoryId,
    String questionText = '',
  }) async {
    try {
      final response =
          await _dio.post('api/user/saved-questions/toggle/', data: {
        'question_id': questionId,
        'question_text': questionText,
        'scope_type': scopeType,
        'licence_id': licenceId ?? '',
        'category_id': categoryId ?? '',
        'bcd_category_id': bcdCategoryId,
      });
      return response.data['is_saved'] as bool?;
    } catch (e) {
      debugPrint('[toggleSavedQuestion] failed: $e');
      return null;
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
        durationSeconds: data['duration_seconds'] as int?,
        bcdCategoryId: (data['bcd_category_id'] as num?)?.toInt() ??
            int.tryParse((data['bcd_category_id'] ?? '').toString()),
      );
    } catch (e) {
      debugPrint('[testAttemptFromJson] parse error: $e');
      return null;
    }
  }

  Future<bool> googleAuth({String? idToken, String? accessToken}) async {
    try {
      final data = idToken != null
          ? {'id_token': idToken}
          : {'access_token': accessToken};
      final response = await _dio.post('api/user/google-auth/', data: data);
      await _dioClient.setTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
      return response.data['is_first_login'] == true;
    } on DioException {
      rethrow;
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

  // ─── BCD v2 endpoints ──────────────────────────────────────────────────────

  /// Safely extract a list from a DRF response, handling both plain lists
  /// and paginated `{"results": [...]}` shapes.
  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) {
      return data['results'] as List<dynamic>;
    }
    return [];
  }


  Future<List<dynamic>> fetchBCDAllCategories() async {
    final response = await _dio.get('api/v2/categories/');
    return _asList(response.data);
  }

  Future<List<dynamic>> fetchBCDSubcategories(int parentCategoryBcdId) async {
    final response =
        await _dio.get('api/v2/categories/$parentCategoryBcdId/subcategories/');
    return _asList(response.data);
  }

  Future<List<dynamic>> fetchBCDTests(int categoryId) async {
    final response = await _dio.get('api/v2/categories/$categoryId/tests/');
    return _asList(response.data);
  }

  Future<List<dynamic>> fetchBCDTestQuestions(int testId) async {
    final response = await _dio.get('api/v2/tests/$testId/questions/');
    return _asList(response.data);
  }

  Future<List<dynamic>> fetchBCDTrafficSigns() async {
    final response = await _dio.get('api/v2/traffic-signs/');
    return _asList(response.data);
  }

  Future<List<dynamic>> fetchBCDDocuments(int categoryId) async {
    final response = await _dio.get('api/v2/categories/$categoryId/documents/');
    return _asList(response.data);
  }

  Future<List<dynamic>> fetchBCDChecklists(int categoryId) async {
    final response =
        await _dio.get('api/v2/categories/$categoryId/checklists/');
    return _asList(response.data);
  }

  Future<void> registerFCMToken(String token, String platform) async {
    try {
      final response = await _dio.post(
        'api/v2/notifications/register-token/',
        data: {'token': token, 'platform': platform},
      );
      debugPrint(
        '[FCM] registerFCMToken success: status=${response.statusCode}, platform=$platform, tokenLen=${token.length}',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FCM] registerFCMToken DioException: status=${e.response?.statusCode}, data=${e.response?.data}',
      );
    } catch (e) {
      debugPrint('[FCM] registerFCMToken failed: $e');
    }
  }

  Future<void> deregisterFCMToken(String token) async {
    try {
      final response = await _dio.delete(
        'api/v2/notifications/register-token/',
        data: {'token': token},
      );
      debugPrint(
        '[FCM] deregisterFCMToken success: status=${response.statusCode}, tokenLen=${token.length}',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FCM] deregisterFCMToken DioException: status=${e.response?.statusCode}, data=${e.response?.data}',
      );
    } catch (e) {
      debugPrint('[FCM] deregisterFCMToken failed: $e');
    }
  }

  Future<List<dynamic>> fetchMyBCDSubscriptions() async {
    final response = await _dio.get('api/v2/my-subscriptions/');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> fetchBCDSubscriptionProducts() async {
    final response = await _dio.get('api/v2/subscription-products/');
    return _asList(response.data);
  }

  Future<String> createBCDPaymentIntent(int productId) async {
    final response = await _dio.post(
      'api/payment/bcd/create-intent/',
      data: {'product_id': productId},
    );
    return response.data['clientSecret'] as String;
  }

  Future<String> createBCDBundlePaymentIntent(List<int> productIds) async {
    final response = await _dio.post(
      'api/payment/bcd/create-bundle-intent/',
      data: {'product_ids': productIds},
    );
    return response.data['clientSecret'] as String;
  }

  /// Notify the backend that a Stripe PaymentIntent succeeded so it can
  /// immediately mark the matching BCDUserSubscription(s) as PAID — before
  /// the asynchronous Stripe webhook arrives.
  Future<void> confirmBCDPayment(String paymentIntentId) async {
    await _dio.post(
      'api/payment/bcd/confirm-payment/',
      data: {'payment_intent_id': paymentIntentId},
    );
  }

  Future<String> createCheckoutSession({
    required String licenceId,
    required String categoryId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _dio.post(
      'api/payment/create-checkout-session/',
      data: {
        'licence_id': licenceId,
        'category_id': categoryId,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
    );
    return response.data['checkout_url'] as String;
  }

  Future<String> createBCDCheckoutSession({
    required int productId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _dio.post(
      'api/payment/bcd/create-checkout-session/',
      data: {
        'product_id': productId,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
    );
    return response.data['checkout_url'] as String;
  }

  /// Build a full URL for a BCD media file (image or document).
  /// [path] is the relative path stored in the DB, e.g. 'bcd/images/foo.png'
  String bcdMediaUrl(String path) {
    final base = _dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/api/bcd-media/$path/';
  }

  // ─── End BCD endpoints ──────────────────────────────────────────────────────

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

  Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String email,
  }) async {
    try {
      final response = await _dio.patch(
        'api/user/self/',
        data: {
          'username': username,
          'email': email,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> setPassword({required String newPassword}) async {
    try {
      await _dio.post(
        'api/user/set-password/',
        data: {'new_password': newPassword},
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to set password: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete('api/user/self/');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<Map<String, dynamic>> fetchBackendVersion() async {
    try {
      final response = await _dio.get('api/version/');
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception('Failed to fetch backend version: $e');
    }
  }
}
