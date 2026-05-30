
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_colors.dart';
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
  String roomTitle = '';
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

  String _status(Map m) =>
      (m['progressStatus'] ?? m['expectedResult'] ?? m['status'] ?? 'NEED_MORE').toString();

  int? _asInt(dynamic v) => v is num ? v.toInt() : null;

  String _pillLabel(String status) {
    switch (status) {
      case 'SUCCESS': return '성공 기준 충족';
      case 'WAITING_CONFIRM': return '멤버 확인 필요';
      case 'NEED_MORE': return '기준까지 부족';
      case 'FAILED': return '미션 실패';
      default: return UiMappers.proofProgressLabel(status);
    }
  }

  Color _pillColor(String status) => UiMappers.proofProgressColor(status);

  String _helperMessage(String status, int remaining) {
    switch (status) {
      case 'SUCCESS': return '목표를 충족했어요!';
      case 'WAITING_CONFIRM': return '멤버 확인을 받으면 기준을 충족해요.';
      case 'NEED_MORE': return remaining > 0 ? '성공 기준까지 $remaining회 부족해요.' : '성공 기준까지 조금 더 필요해요.';
      case 'FAILED': return '성공 기준을 충족하지 못했어요.';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final successCount = members.where((m) => _status(m as Map) == 'SUCCESS').length;
    final waitingCount = members.where((m) => _status(m as Map) == 'WAITING_CONFIRM').length;
    final needCount = members.length - successCount - waitingCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 헤더 ────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => context.go('/rooms/${widget.roomId}'),
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('멤버 진행 현황', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        if (roomTitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(roomTitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.borderLight),
          // ─── 본문 ────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadMembers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Summary ──────────────────────────────────
                    _summaryRow(successCount, waitingCount, needCount),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        '멤버의 성공 인정 수를 기준으로 현재 현황을 보여줘요.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ─── 멤버별 현황 ──────────────────────────────
                    const Text('멤버별 진행 상태', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (errorMessage != null)
                      _errorBox(errorMessage!)
                    else if (members.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('멤버가 없어요', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        ),
                      )
                    else
                      ...members.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _memberCard(m as Map),
                      )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Row ──────────────────────────────────────────────

  Widget _summaryRow(int successCount, int waitingCount, int needCount) {
    return Row(
      children: [
        Expanded(child: _summaryBox('$successCount명', '성공 기준 충족', AppColors.successDark, AppColors.successSoft, Icons.groups_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _summaryBox('$waitingCount명', '멤버 확인 필요', AppColors.primary, AppColors.primarySoft, Icons.person_search_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _summaryBox('$needCount명', '기준까지 부족', AppColors.warning, AppColors.warningSoft, Icons.warning_amber_rounded)),
      ],
    );
  }

  Widget _summaryBox(String value, String label, Color valueColor, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: valueColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: valueColor),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: valueColor)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }

  // ─── 멤버 카드 ────────────────────────────────────────────────

  Widget _memberCard(Map m) {
    final nickname = (m['nickname'] ?? 'member').toString();
    final role = (m['role'] ?? 'MEMBER').toString();
    final submitted = _asInt(m['submittedCount']) ?? 0;
    final confirmed = _asInt(m['confirmedCount']) ?? 0;
    final required = _asInt(m['requiredSuccessCount']) ?? 1;
    final remaining = _asInt(m['remainingRequiredCount']) ?? (required - confirmed).clamp(0, required);
    final status = _status(m);
    final pillLabel = _pillLabel(status);
    final pillColor = _pillColor(status);
    final helperMsg = _helperMessage(status, remaining);
    final progress = required > 0 ? (confirmed / required).clamp(0.0, 1.0) : 0.0;

    final softBg = pillColor.withValues(alpha: 0.1);
    final borderColor = status == 'SUCCESS'
        ? const Color(0xFFBBF7D0)
        : status == 'WAITING_CONFIRM'
            ? const Color(0xFFBFDBFE)
            : status == 'FAILED'
                ? const Color(0xFFFECACA)
                : AppColors.borderLight;

    final helperBg = status == 'SUCCESS' ? AppColors.successSoft
        : status == 'WAITING_CONFIRM' ? AppColors.primarySoft
        : status == 'NEED_MORE' ? AppColors.warningSoft
        : status == 'FAILED' ? AppColors.errorSoft
        : AppColors.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ 상단 row: 아바타 + 이름 + 상태 pill
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: softBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: pillColor.withValues(alpha: 0.35)),
                ),
                child: Center(
                  child: Text(UiMappers.initialFromName(nickname), style: TextStyle(color: pillColor, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(nickname, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                        if (role == 'OWNER') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                            child: const Text('방장', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('인증 제출 $submitted회  ·  성공 인정 $confirmed회', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: pillColor.withValues(alpha: 0.3)),
                ),
                child: Text(pillLabel, style: TextStyle(color: pillColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ─ 프로그레스바
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(pillColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('성공 인정 $confirmed/$required회', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          // ─ 힌트 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: helperBg, borderRadius: BorderRadius.circular(10)),
            child: Text(helperMsg, style: TextStyle(fontSize: 12, color: pillColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── 에러 박스 ────────────────────────────────────────────────

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13))),
      ]),
    );
  }
}
