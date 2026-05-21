import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<UserModel> login({required String email, required String password}) async {
    final response = await apiClient.dio.post(
      '/api/users/login',
      data: {'email': email, 'password': password},
    );

    final loginResponse = LoginResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );

    await tokenStorage.saveAccessToken(loginResponse.accessToken);
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
    await tokenStorage.clearAccessToken();
  }
}
