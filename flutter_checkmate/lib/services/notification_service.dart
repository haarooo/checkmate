import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.dio.get('/api/notifications');
    final data = response.data as List;
    return data
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await apiClient.dio.get('/api/notifications/unread-count');
    final data = response.data as Map<String, dynamic>;
    return data['unreadCount'] as int? ?? 0;
  }

  Future<void> markAsRead(int notificationId) async {
    await apiClient.dio.put('/api/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await apiClient.dio.put('/api/notifications/read-all');
  }
}
