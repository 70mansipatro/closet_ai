import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/services/api_client.dart';
import '../data/auth_repository.dart';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    required this.user,
    required this.error,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final Map<String, dynamic>? user;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._storage)
    : super(
        const AuthState(
          isAuthenticated: false,
          isLoading: true,
          user: null,
          error: null,
        ),
      );

  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    final accessToken = await _storage.read(key: 'accessToken');
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (accessToken == null || refreshToken == null) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        user: null,
      );
      return;
    }

    try {
      final response = await _repository.getProfile();
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response['user'],
      );
    } catch (_) {
      await clearSession();
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        user: null,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(email, password);
      await _persistSession(response);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response['user'],
      );
    } catch (error) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: error.toString(),
        user: null,
      );
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.register(payload);
      await _persistSession(response);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response['user'],
      );
    } catch (error) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: error.toString(),
        user: null,
      );
      rethrow;
    }
  }

  Future<void> requestOtp(String email) async {
    await _repository.forgotPassword(email);
  }

  Future<void> verifyOtp(String email, String otp) async {
    await _repository.verifyOtp(email, otp);
  }

  Future<void> resetPassword(String email, String otp, String password) async {
    await _repository.resetPassword(email, otp, password);
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken != null) {
        await _repository.logout(refreshToken);
      }
    } catch (_) {}

    await clearSession();
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
      user: null,
      error: null,
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  Future<void> _persistSession(Map<String, dynamic> response) async {
    await _storage.write(
      key: 'accessToken',
      value: response['accessToken'] as String,
    );
    await _storage.write(
      key: 'refreshToken',
      value: response['refreshToken'] as String,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient();
    return AuthController(AuthRepository(apiClient), storage);
  },
);

final authInitProvider = FutureProvider<void>((ref) async {
  await ref.read(authControllerProvider.notifier).initialize();
});
