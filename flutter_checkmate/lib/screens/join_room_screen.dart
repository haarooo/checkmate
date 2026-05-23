
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/ui_mappers.dart';
import '../models/room_model.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key, this.initialInviteLinkToken});

  final String? initialInviteLinkToken;

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final inviteCodeController = TextEditingController();
  final inviteLinkTokenController = TextEditingController();

  int? previewRoomId;

  bool isLoading = false;
  bool isPreviewLoading = false;
  String? errorMessage;
  RoomInvitePreviewModel? preview;

  @override
  void initState() {
    super.initState();
    final raw = widget.initialInviteLinkToken;
    if (raw != null && raw.isNotEmpty) {
      final token = _extractInviteToken(raw);
      inviteLinkTokenController.text = token;
      WidgetsBinding.instance.addPostFrameCallback((_) => loadPreview());
    }
  }

  @override
  void dispose() {
    inviteCodeController.dispose();
    inviteLinkTokenController.dispose();
    super.dispose();
  }

  Future<void> loadPreview() async {
    final token = _extractInviteToken(inviteLinkTokenController.text);
    if (token.isEmpty) return;
    setState(() { isPreviewLoading = true; errorMessage = null; });
    try {
      final result = await ref.read(roomServiceProvider).getInvitePreview(token);
      if (!mounted) return;
      setState(() {
        preview = result;
        previewRoomId = result.roomId;
        inviteLinkTokenController.text = token;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => isPreviewLoading = false);
    }
  }

  String _extractInviteToken(String input) {
    var s = input.trim();
    if (s.isEmpty) return '';

    const hashPattern = '#/invite/';
    const pathPattern = '/invite/';

    final hashIdx = s.indexOf(hashPattern);
    if (hashIdx != -1) {
      s = s.substring(hashIdx + hashPattern.length);
    } else {
      final pathIdx = s.indexOf(pathPattern);
      if (pathIdx != -1) {
        s = s.substring(pathIdx + pathPattern.length);
      }
    }

    s = s.trim();
    s = s.split('?').first;
    s = s.split('#').first;
    s = s.split('&').first;
    s = s.trim();

    return Uri.decodeComponent(s);
  }

  Future<void> joinRoom() async {
    final roomId = previewRoomId;
    final inviteCode = inviteCodeController.text.trim();
    if (roomId == null) {
      setState(() => errorMessage = '초대 링크를 먼저 조회해주세요.');
      return;
    }
    if (inviteCode.isEmpty) {
      setState(() => errorMessage = '초대 코드를 입력하세요.');
      return;
    }

    setState(() { isLoading = true; errorMessage = null; });
    try {
      final room = await ref.read(roomServiceProvider).joinRoom(roomId: roomId, inviteCode: inviteCode);
      if (!mounted) return;
      context.go('/rooms/${room.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = preview;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home'))]),
                const Text('방 참여하기', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('친구에게 받은 초대 정보로 참여하세요', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('초대 링크 또는 토큰', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _input(inviteLinkTokenController, '초대 링크를 붙여넣어 주세요', enabled: !isPreviewLoading)),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: isPreviewLoading ? null : loadPreview,
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3B82F6), side: const BorderSide(color: Color(0xFF3B82F6)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: isPreviewLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('조회'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('초대 코드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _input(inviteCodeController, '6자리 초대 코드'),
                  const SizedBox(height: 24),
                  _previewCard(p),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(children: [
                          Icon(Icons.info_outline, color: Color(0xFFF97316), size: 16),
                          SizedBox(width: 8),
                          Text('참여 전 꼭 확인하세요',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                        ]),
                        SizedBox(height: 8),
                        Text('• 방 참여 후 예치금을 납부해야 미션에 참여할 수 있어요.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                        SizedBox(height: 4),
                        Text('• 멤버가 서로 인증을 확인해야 성공으로 인정돼요.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : joinRoom,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('참여하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, {TextInputType? keyboardType, bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _previewCard(RoomInvitePreviewModel? p) {
    final title = p?.title ?? '여름 전까지 4주 운동방';
    final desc = UiMappers.roomDescriptionFallback(title, p?.description);
    final members = p == null ? '3/5명' : '${p.currentMemberCount}/${p.maxMembers}명';
    final point = p == null ? '10,000P' : UiMappers.point(p.stakePoint);
    final type = p?.proofFrequencyType ?? 'DAILY';
    final goal = p == null ? '하루 2회 인증' : UiMappers.frequencyGoalLabel(p.proofFrequencyType, p.requiredProofCount);
    final status = p == null ? '참여 가능' : (p.joinable ? '참여 가능' : UiMappers.statusLabel(p.status));

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle), child: const Icon(Icons.flag_outlined, color: Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(12)), child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: _buildInfoCard(Icons.people_outline, const Color(0xFF3B82F6), '현재 인원', members)), const SizedBox(width: 12), Expanded(child: _buildInfoCard(Icons.account_balance_wallet_outlined, const Color(0xFFEAB308), '예치 포인트', point))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _buildInfoCard(Icons.calendar_today_outlined, const Color(0xFF22C55E), '방식', UiMappers.frequencyTypeLabel(type), compact: true)), const SizedBox(width: 12), Expanded(child: _buildInfoCard(Icons.track_changes, const Color(0xFF8B5CF6), '목표', goal, compact: true))]),
          const SizedBox(height: 12),
          _buildInfoCard(Icons.access_time, const Color(0xFFEF4444), '마감 시간', UiMappers.deadlineLabel(type, p?.deadlineTime ?? '23:00')),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, Color color, String label, String value, {bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: compact ? 13 : 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)))]))]),
    );
  }
}
