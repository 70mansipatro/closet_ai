import 'dart:io';

import 'package:closet_ai/core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';

class WardrobeRepository {
  WardrobeRepository({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = AppConstants.resolveApiBaseUrl();
    _dio.options.connectTimeout = const Duration(seconds: 20);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'accessToken');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('[DIO] ${options.method} ${options.uri}');
          debugPrint(
            '[DIO] authorizationPresent=${token != null && token.isNotEmpty}',
          );
          debugPrint('[DIO] headers=${options.headers}');
          debugPrint(
            '[DIO] body=${options.data is FormData ? 'FormData multipart' : options.data}',
          );
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> fetchItems({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? color,
    String? brand,
    String? season,
    String? occasion,
    String? laundryStatus,
    bool? favorite,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final response = await _dio.get(
      '/clothes',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (color != null && color.isNotEmpty) 'color': color,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (season != null && season.isNotEmpty) 'season': season,
        if (occasion != null && occasion.isNotEmpty) 'occasion': occasion,
        if (laundryStatus != null && laundryStatus.isNotEmpty)
          'laundryStatus': laundryStatus,
        if (favorite != null) 'favorite': favorite.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createItem({
    required Map<String, dynamic> payload,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    late final dynamic requestData;
    late final Options options;

    if (imageFile != null) {
      final formData = FormData.fromMap(payload);
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.uri.pathSegments.last,
          ),
        ),
      );
      requestData = formData;
      options = Options();
    } else if (imageBytes != null) {
      final formData = FormData.fromMap(payload);
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            imageBytes,
            filename: 'upload.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ),
      );
      requestData = formData;
      options = Options();
    } else {
      requestData = payload;
      options = Options(contentType: 'application/json');
    }

    final response = await _dio.post(
      '/clothes',
      data: requestData,
      options: options,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateItem({
    required String id,
    required Map<String, dynamic> payload,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    late final dynamic requestData;
    late final Options options;

    if (imageFile != null) {
      final formData = FormData.fromMap(payload);
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.uri.pathSegments.last,
          ),
        ),
      );
      requestData = formData;
      options = Options();
    } else if (imageBytes != null) {
      final formData = FormData.fromMap(payload);
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            imageBytes,
            filename: 'upload.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ),
      );
      requestData = formData;
      options = Options();
    } else {
      requestData = payload;
      options = Options(contentType: 'application/json');
    }

    final response = await _dio.put(
      '/clothes/$id',
      data: requestData,
      options: options,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> deleteItem(String id) async {
    final response = await _dio.delete('/clothes/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> fetchItem(String id) async {
    final response = await _dio.get('/clothes/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> markAsWorn({
    required String id,
    required String occasion,
    int? rating,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/clothes/$id/wear',
      data: {
        'occasion': occasion,
        if (rating != null) 'rating': rating,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> analyzeImage({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    final formData = FormData();
    final String endpoint = '/clothes/analyze';
    final String imageName = imageFile?.uri.pathSegments.last ?? 'upload.jpg';
    final int? imageSize = imageFile?.lengthSync() ?? imageBytes?.length;

    debugPrint('[ANALYZE] API URL: ${_dio.options.baseUrl}$endpoint');
    debugPrint('[ANALYZE] HTTP Method: POST');
    debugPrint(
      '[ANALYZE] Authorization header: ${_dio.options.headers['Authorization'] ?? 'missing'}',
    );

    if (imageFile != null) {
      debugPrint(
        '[ANALYZE] Uploading image file for analysis path=${imageFile.path} size=$imageSize name=$imageName',
      );
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: imageName,
            contentType: MediaType('image', 'jpeg'),
          ),
        ),
      );
    } else if (imageBytes != null) {
      debugPrint(
        '[ANALYZE] Uploading image bytes for analysis byteLength=${imageBytes.length}',
      );
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            imageBytes,
            filename: imageName,
            contentType: MediaType('image', 'jpeg'),
          ),
        ),
      );
    } else {
      throw ArgumentError('Image file or bytes are required for analysis.');
    }

    debugPrint('[ANALYZE] Multipart request prepared');
    debugPrint('[ANALYZE] Image file path: ${imageFile?.path ?? 'bytes'}');
    debugPrint('[ANALYZE] Image byte size: $imageSize');
    debugPrint('[ANALYZE] FormData: ${formData.fields}');
    debugPrint('[ANALYZE] Request body: ${formData.fields}');

    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final responseData = response.data;
      debugPrint(
        '[ANALYZE] Dio request: ${response.requestOptions.method} ${response.requestOptions.uri}',
      );
      debugPrint('[ANALYZE] Dio response: $responseData');
      debugPrint('[ANALYZE] HTTP Status: ${response.statusCode}');
      debugPrint('[ANALYZE] Response JSON: $responseData');

      if (response.statusCode != null && response.statusCode! >= 400) {
        final message = responseData is Map && responseData['message'] is String
            ? responseData['message'] as String
            : responseData is Map && responseData['error'] is String
            ? responseData['error'] as String
            : 'AI analysis failed with status ${response.statusCode}';
        debugPrint(
          '[ANALYZE] error response statusCode=${response.statusCode} message=$message responseData=$responseData',
        );
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: message,
        );
      }

      if (responseData is Map && responseData['success'] == false) {
        final message = responseData['message'] is String
            ? responseData['message'] as String
            : responseData['error'] is String
            ? responseData['error'] as String
            : 'AI analysis failed';
        debugPrint(
          '[ANALYZE] success false response message=$message responseData=$responseData',
        );
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: message,
        );
      }

      if (responseData is Map && responseData['data'] is Map) {
        return Map<String, dynamic>.from(responseData['data'] as Map);
      }

      if (responseData is Map<String, dynamic>) {
        return responseData;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected analyze response format',
      );
    } on DioException catch (error, stackTrace) {
      debugPrint('[ANALYZE] DioException: ${error.type} ${error.message}');
      debugPrint('[ANALYZE] DioException response: ${error.response?.data}');
      debugPrint('[ANALYZE] StackTrace: $stackTrace');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[ANALYZE] Unexpected exception: $error');
      debugPrint('[ANALYZE] StackTrace: $stackTrace');
      rethrow;
    }
  }
}
