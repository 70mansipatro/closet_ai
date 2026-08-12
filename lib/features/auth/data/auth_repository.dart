import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/services/api_client.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> login(String email, String password) {
    return _apiClient.post(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) {
    final data = <String, dynamic>{
      'name': payload['name']?.trim(),
      'email': payload['email']?.trim(),
      'password': payload['password'],
    };

    final phone = payload['phone']?.toString().trim();
    if (phone != null && phone.isNotEmpty) {
      data['phone'] = phone;
    }

    final gender = payload['gender']?.toString().trim();
    if (gender != null && gender.isNotEmpty && gender != 'prefer-not-to-say') {
      data['gender'] = gender;
    }

    final height = payload['height'];
    if (height != null) {
      data['height'] = height;
    }

    final weight = payload['weight'];
    if (weight != null) {
      data['weight'] = weight;
    }

    final preferredStyle = payload['preferredStyle']?.toString().trim();
    if (preferredStyle != null &&
        preferredStyle.isNotEmpty &&
        preferredStyle != 'casual') {
      data['preferredStyle'] = preferredStyle;
    }

    return _apiClient.post('/auth/register', data: data);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) {
    return _apiClient.post(
      '/auth/forgot-password',
      data: {'email': email.trim()},
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) {
    return _apiClient.post(
      '/auth/verify-otp',
      data: {'email': email.trim(), 'otp': otp},
    );
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String password,
  ) {
    return _apiClient.post(
      '/auth/reset-password',
      data: {'email': email.trim(), 'otp': otp, 'password': password},
    );
  }

  Future<Map<String, dynamic>> getProfile() {
    return _apiClient.get('/auth/profile');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) {
    return _apiClient.put('/auth/profile', data: payload);
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    final formData = FormData();
    if (imageFile != null) {
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.uri.pathSegments.last,
          ),
        ),
      );
    } else if (imageBytes != null) {
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            imageBytes,
            filename: 'profile.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ),
      );
    } else {
      throw ArgumentError('Image file or bytes are required for upload.');
    }

    return _apiClient.postMultipart('/auth/profile/photo', data: formData);
  }

  Future<Map<String, dynamic>> removeProfilePhoto() {
    return _apiClient.delete('/auth/profile/photo');
  }

  Future<Map<String, dynamic>> logout(String refreshToken) {
    return _apiClient.post(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}
