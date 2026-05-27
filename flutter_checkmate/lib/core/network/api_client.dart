import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({required this.tokenStorage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path;

          // 회원가입/로그인은 토큰이 필요 없는 공개 API다.
          // 앱에 예전 토큰이 남아 있어도 Authorization 헤더를 붙이지 않는다.
          final isPublicAuthApi =
              path.contains('/users/signup') || path.contains('/users/login');

          if (!isPublicAuthApi) {
            final token = await tokenStorage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await tokenStorage.clearAccessToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage tokenStorage;
  late final Dio dio;

  static String messageFromError(Object error) {
    if (error is DioException) {
      // 1. timeout (연결/전송/수신 타임아웃 모두 동일 메시지)
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return '요청 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.';
      }

      // 2. statusCode 기반 처리 (서버 응답이 있는 경우)
      final statusCode = error.response?.statusCode;
      if (statusCode != null) return _statusCodeMessage(statusCode);

      // 3. 네트워크 연결 실패 (서버 응답 없음)
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown) {
        return '서버에 연결할 수 없습니다. 인터넷 연결 또는 서버 실행 상태를 확인해 주세요.';
      }

      return '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }

    return '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
  }

  static String _statusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400: return '입력값을 다시 확인해 주세요.';
      case 401: return '로그인이 필요합니다. 다시 로그인해 주세요.';
      case 403: return '이 작업을 할 권한이 없습니다.';
      case 404: return '요청한 정보를 찾을 수 없습니다.';
      case 409: return '현재 상태에서는 처리할 수 없습니다.';
      case 413: return '파일 용량이 너무 큽니다. 더 작은 파일로 다시 시도해 주세요.';
      default:
        if (statusCode >= 500) return '서버에 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.';
        return '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }
}
