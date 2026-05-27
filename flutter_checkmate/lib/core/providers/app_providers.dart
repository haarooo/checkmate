import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../services/point_service.dart';
import '../../services/proof_service.dart';
import '../../services/room_service.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService(apiClient: ref.watch(apiClientProvider));
});

final pointServiceProvider = Provider<PointService>((ref) {
  return PointService(apiClient: ref.watch(apiClientProvider));
});

final proofServiceProvider = Provider<ProofService>((ref) {
  return ProofService(apiClient: ref.watch(apiClientProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(apiClient: ref.watch(apiClientProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
