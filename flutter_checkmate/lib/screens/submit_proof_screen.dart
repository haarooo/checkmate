
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';

class SubmitProofScreen extends ConsumerStatefulWidget {
  const SubmitProofScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends ConsumerState<SubmitProofScreen> {
  final contentController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  XFile? selectedFile;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => selectedFile = file);
  }

  Future<void> pickVideo() async {
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) setState(() => selectedFile = file);
  }

  Future<void> submitProof() async {
    final content = contentController.text.trim();

    if (content.isEmpty && selectedFile == null) {
      setState(() => errorMessage = '텍스트 또는 사진/동영상 중 하나는 필수입니다.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ref.read(proofServiceProvider).submitProof(
        roomId: widget.roomId,
        content: content,
        file: selectedFile,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증을 제출했습니다.')),
      );
      context.go('/rooms/${widget.roomId}/proofs');
    } catch (e) {
      if (!mounted) return;
      final message = (e is DioException && e.response?.statusCode == 409)
          ? '미션 기간이 아니거나, 마감 시간이 지났거나, 제출 가능 횟수를 초과했습니다.'
          : ApiClient.messageFromError(e);
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/rooms/${widget.roomId}'))]),
              const Text('인증 제출', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('미션 인증을 올려주세요', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            ]),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1D5DB))),
                  child: selectedFile == null
                      ? const Center(child: Icon(Icons.image_outlined, size: 48, color: Color(0xFF9CA3AF)))
                      : Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(selectedFile!.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w600)))),
                ),
                const SizedBox(height: 16),
                Row(children: [Expanded(child: _buildUploadButton(Icons.camera_alt, '카메라', const Color(0xFF3B82F6), const Color(0xFFEFF6FF), () => pickImage(ImageSource.camera))), const SizedBox(width: 12), Expanded(child: _buildUploadButton(Icons.image_outlined, '사진', const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), () => pickImage(ImageSource.gallery))), const SizedBox(width: 12), Expanded(child: _buildUploadButton(Icons.videocam_outlined, '동영상', const Color(0xFFEC4899), const Color(0xFFFCE7F3), pickVideo))]),
                const SizedBox(height: 24),
                const Text('인증 내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: '오늘의 운동/식단 인증 내용을 입력하세요',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, color: Color(0xFFF97316), size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('인증 제출 안내', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                      SizedBox(height: 8),
                      Text('• 텍스트 또는 사진/동영상 중 하나는 필수입니다\n• 제출만으로는 완료가 아니에요. 다른 멤버가 확인해야 성공으로 인정됩니다\n• 본인의 인증은 본인이 직접 확인할 수 없어요', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5)),
                    ])),
                  ]),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                ],
                const SizedBox(height: 96),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : submitProof,
                icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.upload),
                label: Text(isLoading ? '제출 중...' : '인증 제출하기', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String label, Color iconColor, Color bgColor, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(icon, color: iconColor, size: 24), const SizedBox(height: 6), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: iconColor))])),
      );
}
