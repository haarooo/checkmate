import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/api/users/login',
      data: {'email': email, 'password': password},
    );

    final loginResponse = LoginResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );

    await tokenStorage.saveAccessToken(loginResponse.accessToken);
    await registerCurrentDeviceTokenSafely();

    return loginResponse.user;
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) async {
    await apiClient.dio.post(
      '/api/users/signup',
      data: {
        'email': email,
        'password': password,
        'name': name,
        'nickname': nickname,
      },
    );
  }

  Future<UserModel> getMe() async {
    final response = await apiClient.dio.get('/api/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> hasToken() async {
    final token = await tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await deactivateCurrentDeviceTokenSafely();
    await tokenStorage.clearAccessToken();
  }

  Future<void> registerCurrentDeviceTokenSafely() async {
    try {
      if (kIsWeb) return;
      final platform = _currentPlatform();
      if (platform == null) return;

      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) return;

      await apiClient.dio.post(
        '/api/device-tokens',
        data: {'token': token, 'platform': platform},
      );
    } catch (e) {
      debugPrint('[FCM] device token 등록 실패: $e');
    }
  }

  Future<void> deactivateCurrentDeviceTokenSafely() async {
    try {
      if (kIsWeb) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await apiClient.dio.delete('/api/device-tokens', data: {'token': token});
    } catch (e) {
      debugPrint('[FCM] device token 비활성화 실패: $e');
    }
  }

  String? _currentPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'ANDROID';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'IOS';
    return null;
  }
}
