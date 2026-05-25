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

    // 1. accessToken을 먼저 저장한다.
    // 이유: /api/device-tokens는 인증 API라 Authorization 헤더가 필요하다.
    await tokenStorage.saveAccessToken(loginResponse.accessToken);

    // 2. 로그인 성공 후 현재 기기의 FCM token을 서버에 등록한다.
    // 실패해도 로그인 자체는 성공으로 유지한다.
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
    // 로그아웃 시 현재 기기 token을 비활성화한다.
    // 실패하더라도 로컬 accessToken은 반드시 지운다.
    await deactivateCurrentDeviceTokenSafely();
    await tokenStorage.clearAccessToken();
  }

  /// 현재 기기의 FCM token을 서버 device_tokens 테이블에 등록한다.
  ///
  /// 호출 시점:
  /// - 로그인 성공 후
  /// - 기존 세션 복구 후
  ///
  /// 이 메서드는 실패해도 예외를 밖으로 던지지 않는다.
  /// 이유:
  /// - FCM 등록은 부가기능이다.
  /// - FCM 실패 때문에 로그인/앱 진입이 막히면 사용자 경험이 나빠진다.
  Future<void> registerCurrentDeviceTokenSafely() async {
    try {
      if (kIsWeb) {
        debugPrint('[FCM] Web 환경은 현재 device token 등록 스킵');
        return;
      }

      final platform = _currentPlatform();
      if (platform == null) {
        debugPrint('[FCM] 지원하지 않는 플랫폼이라 device token 등록 스킵');
        return;
      }

      final permission = await FirebaseMessaging.instance.requestPermission();
      debugPrint('[FCM] permission: ${permission.authorizationStatus}');

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('[FCM] token이 없어 device token 등록 스킵');
        return;
      }

      await apiClient.dio.post(
        '/api/device-tokens',
        data: {
          'token': token,
          'platform': platform,
        },
      );

      debugPrint('[FCM] device token 등록 성공');
    } catch (e) {
      debugPrint('[FCM] device token 등록 실패: $e');
    }
  }

  /// 로그아웃 시 현재 기기의 FCM token을 서버에서 active=false로 전환한다.
  ///
  /// 실패해도 로그아웃은 계속 진행한다.
  Future<void> deactivateCurrentDeviceTokenSafely() async {
    try {
      if (kIsWeb) return;

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      await apiClient.dio.delete(
        '/api/device-tokens',
        data: {
          'token': token,
        },
      );

      debugPrint('[FCM] device token 비활성화 성공');
    } catch (e) {
      debugPrint('[FCM] device token 비활성화 실패: $e');
    }
  }

  String? _currentPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ANDROID';
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'IOS';
    }

    return null;
  }
}