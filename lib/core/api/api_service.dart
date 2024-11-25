import 'dart:typed_data';

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

  Future<List<Question>> fetchQuestions(
      String licenceId, String categoryId) async {
    final response = await _dio
        .get('api/licences/$licenceId/categories/$categoryId/questions/');

    return response.data['results'];
  }

  Future<String> fetchImage(
      String licenceId, String categoryId, String imagePath) async {
    // final imageUrl =
    //     'http://192.168.1.79:8000/secure-media/$licenceId/$categoryId/$imagePath/';
    final imageUrl =
        'http://10.0.2.2:8000/secure-media/$licenceId/$categoryId/$imagePath/';

    return imageUrl;
    // try {
    //   final response = await _dio.get(
    //     imageUrl,
    //   );
    //   print(response.data); // This will print Uint8List
    //   return Uint8List.fromList(response.data);
    //   // print('Response data type: ${response.data.runtimeType}');

    //   return response.data; // This will be Uint8List
    // } catch (e) {
    //   throw Exception('Failed to load image: $e');
    // }
  }
}
