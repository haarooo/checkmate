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
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      if (responseData is Map) {
        for (final key in ['message', 'detail', 'error']) {
          final value = responseData[key];
          if (value is String && _isUserFriendlyMessage(value)) {
            return value;
          }
        }
      } else if (responseData is String && _isUserFriendlyMessage(responseData)) {
        return responseData;
      }

      if (statusCode != null) return _statusCodeMessage(statusCode);

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return '네트워크 연결을 확인해주세요.';
      }

      return '네트워크 연결을 확인해주세요.';
    }

    return '요청 처리 중 문제가 발생했습니다.';
  }

  static bool _isUserFriendlyMessage(String message) {
    if (message.isEmpty) return false;
    if (message.length > 100) return false;
    final lower = message.toLowerCase();
    if (lower.contains('<html')) return false;
    if (lower.contains('dioexception')) return false;
    if (lower.contains('status code')) return false;
    if (lower.contains('this exception was thrown')) return false;
    if (lower.contains('requestoptions')) return false;
    if (lower.contains('stacktrace')) return false;
    const devOnlyMessages = {
      'conflict', 'bad request', 'forbidden', 'unauthorized',
      'not found', 'internal server error', 'ok', 'created',
    };
    if (devOnlyMessages.contains(message.trim().toLowerCase())) return false;
    return true;
  }

  static String _statusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400: return '입력값을 확인해주세요.';
      case 401: return '로그인이 필요합니다.';
      case 403: return '권한이 없습니다.';
      case 404: return '대상을 찾을 수 없습니다.';
      case 409: return '현재 요청을 처리할 수 없는 상태입니다.';
      case 413: return '파일 용량이 너무 큽니다. 더 작은 파일로 다시 시도해주세요.';
      case 500: return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:  return '요청 처리 중 문제가 발생했습니다.';
    }
  }
}
