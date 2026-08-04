import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = AppConstants.resolveApiBaseUrl();
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'accessToken');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
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

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> _parseResponse(
    Response<dynamic> response,
  ) async {
    if (response.data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return {'data': response.data};
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _dio.get(path);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post(path, data: data);
    return _parseResponse(response);
  }
}
