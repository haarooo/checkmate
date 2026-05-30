import '../core/network/api_client.dart';
import '../models/point_model.dart';

class PointService {
  PointService({required this.apiClient});

  final ApiClient apiClient;

  Future<PointWalletModel> getMyWallet() async {
    final response = await apiClient.dio.get('/api/points/me');
    return PointWalletModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PointLedgerModel>> getMyLedgers() async {
    final response = await apiClient.dio.get('/api/points/me/ledgers');
    final data = response.data as List;
    return data.map((item) => PointLedgerModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<PointWalletModel> testCharge(int amount) async {
    final response = await apiClient.dio.post('/api/points/test/charge', data: {'amount': amount});
    return PointWalletModel.fromJson(response.data as Map<String, dynamic>);
  }
}
