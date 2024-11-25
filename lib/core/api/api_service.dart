import 'package:dio/dio.dart';
import 'dio_client.dart';

class ApiService {
  final Dio _dio = DioClient().dio;
  final DioClient _dioClient = DioClient();

  Future<void> authenticate(String username, String password) async {
    try {
      final response = await _dio.post(
        'token/',
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

  Future<List<dynamic>> fetchLicenses() async {
    try {
      final response = await _dio.get('licences/');
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
      'licences/$licenceTypeId/',
    );
    return response.data['categories'];
  }

  Future<List<dynamic>> fetchQuestions(
      String licenceId, String categoryId) async {
    final response =
        await _dio.get('licences/$licenceId/categories/$categoryId/questions/');

    return response.data['results'];
  }
}
