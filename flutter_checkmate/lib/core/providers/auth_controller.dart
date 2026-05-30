import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'app_providers.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});

class AuthController extends ChangeNotifier {
  AuthController(this._authService) {
    restoreSession();
  }

  final AuthService _authService;

  AuthStatus status = AuthStatus.loading;
  UserModel? currentUser;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  Future<void> restoreSession() async {
    status = AuthStatus.loading;
    notifyListeners();

    final hasToken = await _authService.hasToken();
    if (!hasToken) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      currentUser = await _authService.getMe();
      await _authService.registerCurrentDeviceTokenSafely();
      status = AuthStatus.authenticated;
      errorMessage = null;
    } catch (_) {
      await _authService.logout();
      currentUser = null;
      status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    errorMessage = null;

    try {
      currentUser = await _authService.login(email: email, password: password);
      status = AuthStatus.authenticated;
    } catch (e) {
      currentUser = null;
      status = AuthStatus.unauthenticated;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
