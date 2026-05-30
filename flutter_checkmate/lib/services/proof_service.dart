import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/api_client.dart';
import '../models/proof_model.dart';

class ProofService {
  ProofService({required this.apiClient});

  final ApiClient apiClient;

  Future<ProofSubmitResponseModel> submitProof({
    required int roomId,
    String? content,
    XFile? file,
  }) async {
    final formData = FormData();

    if (content != null && content.trim().isNotEmpty) {
      formData.fields.add(MapEntry('content', content.trim()));
    }

    if (file != null) {
      final bytes = await file.readAsBytes();
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            bytes,
            filename: file.name,
            contentType: _guessContentType(file.name, file.mimeType),
          ),
        ),
      );
    }

    final response = await apiClient.dio.post(
      '/api/rooms/$roomId/proofs',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return ProofSubmitResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ProofFeedItemModel>> getProofFeed(int roomId) async {
    final response = await apiClient.dio.get('/api/rooms/$roomId/proofs');
    final data = response.data as List;
    return data.map((item) => ProofFeedItemModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> confirmProof(int proofId) async {
    final response = await apiClient.dio.post('/api/proofs/$proofId/confirm');
    return response.data as Map<String, dynamic>;
  }

  MediaType? _guessContentType(String fileName, String? mimeType) {
    if (mimeType != null && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      return MediaType(parts[0], parts[1]);
    }

    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return MediaType('image', 'jpeg');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.mp4')) return MediaType('video', 'mp4');
    if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
    if (lower.endsWith('.webm')) return MediaType('video', 'webm');
    return null;
  }
}
