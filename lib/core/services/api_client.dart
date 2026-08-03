import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class ApiClient {
  ApiClient() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> get(String path) async {
    final token = await _storage.read(key: 'accessToken');
    final response = await _dio.get(
      path,
      options: Options(
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final token = await _storage.read(key: 'accessToken');
    final response = await _dio.post(
      path,
      data: data,
      options: Options(
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
