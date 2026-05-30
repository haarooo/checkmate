import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../ui/checkmate_ui.dart';

class SubmitProofScreen extends ConsumerStatefulWidget {
  const SubmitProofScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends ConsumerState<SubmitProofScreen> {
  final content = TextEditingController();
  XFile? file;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    content.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final selected = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (selected != null) {
      setState(() => file = selected);
    }
  }

  Future<void> submit() async {
    if (content.text.trim().isEmpty && file == null) {
      setState(() => error = '인증 내용 또는 이미지를 올려 주세요.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await ref.read(proofServiceProvider).submitProof(
            roomId: widget.roomId,
            content: content.text.trim(),
            file: file,
          );
      if (!mounted) return;
      context.go('/rooms/${widget.roomId}/proofs');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e is DioException ? ApiClient.messageFromError(e) : '인증 제출에 실패했어요.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CMTopBar(title: '인증 올리기', subtitle: '오늘의 미션 인증을 제출해 주세요.', onBack: () => context.canPop() ? context.pop() : context.go('/rooms/${widget.roomId}')),
          const SizedBox(height: 24),
          CMGradientCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '오늘 인증을\n기록해 보세요!',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.25),
                  ),
                ),
                Icon(Icons.upload_rounded, color: Colors.white.withValues(alpha: 0.95), size: 54),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('인증 내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: CMColors.text)),
          const SizedBox(height: 8),
          TextField(
            controller: content,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '예: 오늘 운동 완료! 러닝 40분 + 근력 20분',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CMColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CMColors.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CMColors.blue, width: 1.5)),
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CMColors.line),
              ),
              child: Center(
                child: file == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.image_rounded, color: CMColors.blue, size: 40),
                          SizedBox(height: 10),
                          Text('인증 사진 선택하기', style: TextStyle(color: CMColors.blue, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('사진은 선택 사항이에요.', style: TextStyle(color: CMColors.sub, fontSize: 11)),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: CMColors.green, size: 40),
                          const SizedBox(height: 10),
                          Text(file!.name, style: const TextStyle(color: CMColors.text, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text('사진이 선택됐어요.', style: TextStyle(color: CMColors.sub, fontSize: 11)),
                        ],
                      ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: CMColors.red, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 24),
          CMPrimaryButton(label: '인증 제출하기', icon: Icons.upload_rounded, onPressed: submit, loading: loading),
        ],
      ),
    );
  }
}
