import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({required this.tokenStorage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path;
          final isPublic = path.contains('/api/users/login') ||
              path.contains('/api/users/signup') ||
              path.contains('/api/rooms/invite/');

          if (!isPublic) {
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
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return '서버 응답이 지연되고 있어요.';
      }
      if (error.response?.statusCode == 403) {
        return '권한이 없어요.';
      }
      if (error.response?.statusCode == 404) {
        return '요청한 정보를 찾을 수 없어요.';
      }
    }
    return '처리 중 오류가 발생했어요.';
  }
}
