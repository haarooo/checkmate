
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/ui_mappers.dart';

class MemberStatusScreen extends ConsumerStatefulWidget {
  const MemberStatusScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<MemberStatusScreen> createState() => _MemberStatusScreenState();
}

class _MemberStatusScreenState extends ConsumerState<MemberStatusScreen> {
  bool isLoading = true;
  String? errorMessage;
  String roomTitle = '여름 전까지 4주 운동방';
  List<dynamic> members = [];

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final service = ref.read(roomServiceProvider);
      try {
        final stats = await service.getMemberStats(widget.roomId);
        if (!mounted) return;
        setState(() {
          roomTitle = (stats['roomTitle'] ?? roomTitle).toString();
          members = (stats['members'] as List?) ?? [];
        });
      } catch (_) {
        final roomMembers = await service.getRoomMembers(widget.roomId);
        if (!mounted) return;
        setState(() {
          members = roomMembers
              .map((m) => {
                    'userId': m.userId,
                    'nickname': m.nickname,
                    'role': m.role,
                    'submittedCount': 0,
                    'confirmedCount': 0,
                    'requiredSuccessCount': 1,
                    'remainingRequiredCount': 1,
                    'proofRate': 0.0,
                    'expectedResult': m.status == 'STAKED' ? 'WAITING_CONFIRM' : 'NEED_MORE',
                  })
              .toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final successCount = members.where((m) => _status(m) == 'SUCCESS').length;
    final waitingCount = members.where((m) => _status(m) == 'WAITING_CONFIRM').length;
    final needCount = members.length - successCount - waitingCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/rooms/${widget.roomId}'))]),
              const Text('멤버별 현황', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(roomTitle, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            ]),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadMembers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _buildSummaryBox('$successCount', '목표 달성', const Color(0xFF22C55E))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryBox('$waitingCount', '확인 대기', const Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryBox('$needCount', '추가 필요', const Color(0xFFF97316))),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    '확인 완료된 인증 수를 기준으로 목표 달성을 계산해요.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                  else if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
                      ]),
                    )
                  else if (members.isEmpty)
                    const Text('멤버가 없습니다.', style: TextStyle(color: Color(0xFF6B7280)))
                  else
                    ...members.map((m) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _memberCardFromMap(m as Map))),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCardFromMap(Map m) {
    final nickname = (m['nickname'] ?? 'member').toString();
    final role = (m['role'] ?? 'MEMBER').toString();
    final submitted = _asInt(m['submittedCount']) ?? 0;
    final confirmed = _asInt(m['confirmedCount']) ?? 0;
    final required = _asInt(m['requiredSuccessCount']) ?? 2;
    final status = _status(m);
    return _buildMemberCard(
      initial: UiMappers.initialFromName(nickname),
      name: nickname,
      role: role == 'OWNER' ? '방장' : null,
      subtitle: '제출 $submitted · 확인 $confirmed',
      status: UiMappers.proofProgressLabel(status),
      statusColor: UiMappers.proofProgressColor(status),
      submitted: '$submitted',
      confirmed: '$confirmed',
      required: required,
    );
  }

  String _status(Map m) =>
      (m['progressStatus'] ?? m['expectedResult'] ?? m['status'] ?? 'NEED_MORE').toString();

  int? _asInt(dynamic v) => v is num ? v.toInt() : null;

  Widget _buildSummaryBox(String value, String label, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6))),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _buildMemberCard({
    required String initial,
    required String name,
    String? role,
    required String subtitle,
    required String status,
    required Color statusColor,
    required String submitted,
    required String confirmed,
    required int required,
  }) {
    final confirmedInt = int.tryParse(confirmed) ?? 0;
    final submittedInt = int.tryParse(submitted) ?? 0;
    final progress = required == 0 ? 0.0 : (confirmedInt / required).clamp(0.0, 1.0).toDouble();

    final String hint;
    final Color hintBgColor;
    final Color hintTextColor;
    if (required == 0) {
      hint = '목표가 아직 설정되지 않았어요';
      hintBgColor = const Color(0xFFF3F4F6);
      hintTextColor = const Color(0xFF6B7280);
    } else if (confirmedInt >= required) {
      hint = '목표를 달성했어요';
      hintBgColor = const Color(0xFFF0FDF4);
      hintTextColor = const Color(0xFF22C55E);
    } else if (submittedInt >= required) {
      hint = '제출은 충분해요. 멤버 확인을 기다리는 중이에요';
      hintBgColor = const Color(0xFFEFF6FF);
      hintTextColor = const Color(0xFF3B82F6);
    } else {
      hint = '목표까지 확인 ${required - confirmedInt}개 더 필요해요';
      hintBgColor = const Color(0xFFFFF7ED);
      hintTextColor = const Color(0xFFF97316);
    }

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.35)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (role != null) ...[
                  const SizedBox(width: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(4)),
                      child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
                ],
              ]),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            ]),
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
              child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox(submitted, '제출 완료', const Color(0xFF3B82F6))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(confirmed, '확인 완료', const Color(0xFF22C55E))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor)),
            ),
          ),
          const SizedBox(width: 8),
          Text('확인 완료 $confirmed/$required',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: hintBgColor, borderRadius: BorderRadius.circular(8)),
          child: Text(hint,
              style: TextStyle(fontSize: 12, color: hintTextColor, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildStatBox(String value, String label, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ]),
      );
}
