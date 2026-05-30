import '../core/network/api_client.dart';
import '../models/room_model.dart';
import '../models/settlement_model.dart';

class RoomService {
  RoomService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<RoomSummaryModel>> getMyRooms() async {
    final response = await apiClient.dio.get('/api/rooms');
    final data = response.data as List;
    return data.map((item) => RoomSummaryModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<RoomDetailModel> createRoom({
    required String title,
    required String description,
    required int durationDays,
    required String deadlineTime,
    required int stakePoint,
    required int maxMembers,
    required String proofFrequencyType,
    required int requiredProofCount,
  }) async {
    final response = await apiClient.dio.post(
      '/api/rooms',
      data: {
        'title': title,
        'description': description,
        'durationDays': durationDays,
        'deadlineTime': deadlineTime,
        'stakePoint': stakePoint,
        'maxMembers': maxMembers,
        'proofFrequencyType': proofFrequencyType,
        'requiredProofCount': requiredProofCount,
      },
    );

    return RoomDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoomDetailModel> getRoomDetail(int roomId) async {
    final response = await apiClient.dio.get('/api/rooms/$roomId');
    return RoomDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RoomMemberModel>> getRoomMembers(int roomId) async {
    final response = await apiClient.dio.get('/api/rooms/$roomId/members');
    final data = response.data as List;
    return data.map((item) => RoomMemberModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<RoomInvitePreviewModel> getInvitePreview(String inviteLinkToken) async {
    final response = await apiClient.dio.get('/api/rooms/invite/$inviteLinkToken');
    return RoomInvitePreviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoomDetailModel> joinRoom({
    required int roomId,
    required String inviteCode,
  }) async {
    final response = await apiClient.dio.post('/api/rooms/$roomId/join', data: {'inviteCode': inviteCode});
    return RoomDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoomDetailModel> stakeRoom(int roomId) async {
    final response = await apiClient.dio.post('/api/rooms/$roomId/stake');
    return RoomDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoomDetailModel> startRoom(int roomId) async {
    final response = await apiClient.dio.post('/api/rooms/$roomId/start');
    return RoomDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getTodayStatus(int roomId) async {
    final response = await apiClient.dio.get('/api/rooms/$roomId/today-status');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMemberStats(int roomId) async {
    final response = await apiClient.dio.get('/api/rooms/$roomId/members/stats');
    return response.data as Map<String, dynamic>;
  }

  Future<SettlementModel> settleRoom(int roomId) async {
    final response = await apiClient.dio.post('/api/rooms/$roomId/settle');
    return SettlementModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SettlementModel> getSettlement(int roomId) async {
    final response = await apiClient.dio.get('/api/rooms/$roomId/settlement');
    return SettlementModel.fromJson(response.data as Map<String, dynamic>);
  }
}
