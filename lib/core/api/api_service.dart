import 'package:dio/dio.dart';

import 'package:taxi_exam_app/core/models/question.dart';
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

      _dioClient.accessToken = response.data['access'];
      _dioClient.refreshToken = response.data['refresh'];
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
      final response = await _dio.get('api/user/self');
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
    final response = await _dio.get(
        'api/licences/$licenceId/categories/$categoryId/questions/',
        queryParameters: {
          'page_size': pageSize,
          'randomize': randomize,
        });

    return response.data['results'];
  }

  Future<String> fetchImage(
      String licenceId, String categoryId, String imagePath) async {
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
}
