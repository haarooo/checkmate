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
          final token = await tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
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
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ??
            responseData['detail'] ??
            responseData['error'];
        if (message != null) return message.toString();
      }

      if (error.response?.statusCode == 401) {
        return '로그인이 필요하거나 로그인 정보가 올바르지 않습니다.';
      }

      if (error.response?.statusCode == 403) {
        return '접근 권한이 없습니다.';
      }

      if (error.response?.statusCode == 409) {
        return '현재 상태에서는 처리할 수 없습니다.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return '백엔드 서버에 연결할 수 없습니다. Spring Boot가 켜져 있는지 확인하세요.';
      }

      return error.message ?? '요청 처리 중 오류가 발생했습니다.';
    }

    return error.toString();
  }
}
