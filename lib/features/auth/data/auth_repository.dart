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
    return _apiClient.post(
      '/auth/register',
      data: {
        'name': payload['name']?.trim(),
        'email': payload['email']?.trim(),
        'phone': payload['phone']?.trim() ?? '',
        'password': payload['password'],
        'gender': payload['gender'] ?? 'prefer-not-to-say',
        'height': payload['height'],
        'weight': payload['weight'],
        'preferredStyle': payload['preferredStyle'] ?? 'casual',
      },
    );
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

  Future<Map<String, dynamic>> logout(String refreshToken) {
    return _apiClient.post(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}
