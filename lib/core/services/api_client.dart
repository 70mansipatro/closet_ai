import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class ApiClient {
  ApiClient() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('[DIO] ${options.method} ${options.uri}');
          debugPrint('[DIO] body: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[DIO] response ${response.statusCode} ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('[DIO] error ${error.type} ${error.message}');
          if (error.response != null) {
            debugPrint('[DIO] response data: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> get(String path) async {
    final token = await _storage.read(key: 'accessToken');
    final response = await _dio.get(
      path,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
