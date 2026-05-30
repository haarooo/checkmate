import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../models/room_model.dart';
import '../ui/checkmate_ui.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key, this.initialInviteLinkToken});

  final String? initialInviteLinkToken;

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final inviteLink = TextEditingController();
  final code = TextEditingController();

  RoomInvitePreviewModel? preview;
  String? loadedToken;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.initialInviteLinkToken != null && widget.initialInviteLinkToken!.isNotEmpty) {
      inviteLink.text = widget.initialInviteLinkToken!;
      _loadPreview(widget.initialInviteLinkToken!);
    }
  }

  @override
  void dispose() {
    inviteLink.dispose();
    code.dispose();
    super.dispose();
  }

  String _extractToken(String input) {
    final value = input.trim();
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    if (value.contains('/')) {
      return value.split('/').where((e) => e.isNotEmpty).last;
    }
    return value;
  }

  Future<void> _loadPreviewFromInput() async {
    final token = _extractToken(inviteLink.text);
    if (token.isEmpty) {
      setState(() => error = '초대 링크 또는 토큰을 입력해 주세요.');
      return;
    }
    await _loadPreview(token);
  }

  Future<void> _loadPreview(String token) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await ref.read(roomServiceProvider).getInvitePreview(token);
      if (!mounted) return;
      setState(() {
        preview = result;
        loadedToken = token;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e is DioException ? ApiClient.messageFromError(e) : '초대 정보를 불러오지 못했어요.';
        loading = false;
      });
    }
  }

  Future<void> join() async {
    if (preview == null) {
      setState(() => error = '먼저 방 정보를 확인해 주세요.');
      return;
    }
    if (code.text.trim().isEmpty) {
      setState(() => error = '초대코드를 입력해 주세요.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final room = await ref.read(roomServiceProvider).joinRoom(
            roomId: preview!.roomId,
            inviteCode: code.text.trim(),
          );
      if (!mounted) return;
      context.go('/rooms/${room.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e is DioException ? ApiClient.messageFromError(e) : '방 참여에 실패했어요.';
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
          CMTopBar(
            title: '미션방 참여하기',
            subtitle: '초대 링크와 초대코드로 방에 참여해요.',
            onBack: () => context.canPop() ? context.pop() : context.go('/rooms'),
          ),
          const SizedBox(height: 24),
          CMGradientCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '초대받은 방을\n확인해 보세요!',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.25),
                  ),
                ),
                Icon(Icons.link_rounded, color: Colors.white.withValues(alpha: 0.9), size: 54),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('초대 링크 / 토큰', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: CMColors.text)),
          const SizedBox(height: 8),
          TextField(
            controller: inviteLink,
            decoration: _inputDecoration('https://checkmate.app/invite/UUID 또는 UUID'),
          ),
          const SizedBox(height: 10),
          CMOutlineButton(
            label: '방 정보 확인하기',
            icon: Icons.search_rounded,
            onPressed: loading ? null : _loadPreviewFromInput,
            height: 45,
          ),
          const SizedBox(height: 18),
          if (preview != null) _PreviewCard(preview: preview!, token: loadedToken),
          const SizedBox(height: 18),
          const Text('초대코드', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: CMColors.text)),
          const SizedBox(height: 8),
          TextField(
            controller: code,
            decoration: _inputDecoration('초대코드 입력'),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: CMColors.red, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 22),
          CMPrimaryButton(label: '미션방 참여하기', icon: Icons.login_rounded, onPressed: join, loading: loading),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: CMColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: CMColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: CMColors.blue, width: 1.5)),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview, required this.token});
  final RoomInvitePreviewModel preview;
  final String? token;

  @override
  Widget build(BuildContext context) {
    return CMCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: CMColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(preview.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: CMColors.text, fontWeight: FontWeight.w900)),
              ),
              CMPill(
                label: preview.joinable ? '참여 가능' : '참여 불가',
                color: preview.joinable ? CMColors.green : CMColors.red,
                background: preview.joinable ? CMColors.greenBg : CMColors.redBg,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(preview.description ?? '친구들과 함께 미션 완주하기', style: const TextStyle(color: CMColors.sub, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Metric(label: '인원', value: '${preview.currentMemberCount}/${preview.maxMembers}명')),
              Expanded(child: _Metric(label: '예치금', value: formatPoint(preview.stakePoint))),
              Expanded(child: _Metric(label: '인증', value: proofFrequencyText(preview.proofFrequencyType, preview.requiredProofCount))),
            ],
          ),
          if (token != null) ...[
            const SizedBox(height: 12),
            Text('초대 토큰: $token', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CMColors.muted, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: CMColors.sub, fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: CMColors.text, fontWeight: FontWeight.w900, fontSize: 12)),
    ]);
  }
}
