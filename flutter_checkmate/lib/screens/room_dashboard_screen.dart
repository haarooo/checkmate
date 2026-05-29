
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
import '../core/utils/ui_mappers.dart';
import '../models/room_model.dart';

class RoomDashboardScreen extends ConsumerStatefulWidget {
  const RoomDashboardScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<RoomDashboardScreen> createState() => _RoomDashboardScreenState();
}

class _RoomDashboardScreenState extends ConsumerState<RoomDashboardScreen> {
  bool isLoading = true;
  bool isActionLoading = false;
  String? errorMessage;
  RoomDetailModel? room;
  List<RoomMemberModel> members = [];
  Map<String, dynamic>? todayStatus;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final service = ref.read(roomServiceProvider);
      final detail = await service.getRoomDetail(widget.roomId);
      final memberList = await service.getRoomMembers(widget.roomId);
      Map<String, dynamic>? today;
      if (detail.status == 'IN_PROGRESS') {
        try {
          today = await service.getTodayStatus(widget.roomId);
        } catch (_) {
          today = null;
        }
      }
      if (!mounted) return;
      setState(() {
        room = detail;
        members = memberList;
        todayStatus = today;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> stakeRoom() async => _runAction(
    () => ref.read(roomServiceProvider).stakeRoom(widget.roomId),
    customError: (code) {
      if (code == 400) return '포인트가 부족합니다.';
      if (code == 409) return '이미 예치금을 납부했습니다.';
      return null;
    },
  );

  Future<void> startRoom() async => _runAction(
    () => ref.read(roomServiceProvider).startRoom(widget.roomId),
    customError: (code) {
      if (code == 400 || code == 403 || code == 409) return '방을 시작할 수 없습니다. 인원과 예치 상태를 확인해 주세요.';
      return null;
    },
  );

  Future<void> _settleRoom() async {
    setState(() { isActionLoading = true; errorMessage = null; });
    try {
      await ref.read(roomServiceProvider).settleRoom(widget.roomId);
      if (!mounted) return;
      context.push('/rooms/${widget.roomId}/settlement');
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 409) {
        // 409는 "이미 정산됨"일 수도 있으므로 결과 조회를 먼저 시도
        try {
          await ref.read(roomServiceProvider).getSettlement(widget.roomId);
          if (!mounted) return;
          context.push('/rooms/${widget.roomId}/settlement');
        } catch (_) {
          if (!mounted) return;
          setState(() => errorMessage = ApiClient.messageFromError(e));
        }
        return;
      }
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  bool _canSettle(RoomDetailModel room) {
    if (room.status != 'IN_PROGRESS') return false;
    final endDate = room.missionEndDate;
    if (endDate == null) return false;
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final todayKST = DateTime(now.year, now.month, now.day);
    final endKST = DateTime(endDate.year, endDate.month, endDate.day);
    if (todayKST.isAfter(endKST)) return true;
    if (todayKST.isAtSameMomentAs(endKST)) {
      final parts = room.deadlineTime.split(':');
      final dh = int.tryParse(parts[0]) ?? 23;
      final dm = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return (now.hour * 60 + now.minute) > (dh * 60 + dm);
    }
    return false;
  }

  Future<void> _runAction(
    Future<RoomDetailModel> Function() action, {
    String? Function(int? statusCode)? customError,
  }) async {
    setState(() { isActionLoading = true; errorMessage = null; });
    try {
      await action();
      await loadDashboard();
    } catch (e) {
      if (!mounted) return;
      final statusCode = (e is DioException) ? e.response?.statusCode : null;
      final message = customError?.call(statusCode) ?? ApiClient.messageFromError(e);
      setState(() => errorMessage = message);
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = room;

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
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
                    const Spacer(),
                    // 채팅 아이콘: 상태 배지 왼쪽에 위치
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, size: 22),
                      color: const Color(0xFF3B82F6),
                      tooltip: '채팅',
                      onPressed: () => context.push('/rooms/${widget.roomId}/chat'),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: UiMappers.statusColor(currentRoom?.status ?? 'IN_PROGRESS'), borderRadius: BorderRadius.circular(16)),
                      child: Text(UiMappers.statusLabel(currentRoom?.status ?? 'IN_PROGRESS'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Text(currentRoom?.title ?? '여름 전까지 4주 운동방', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(UiMappers.roomDescriptionFallback(currentRoom?.title ?? '여름 전까지 4주 운동방', currentRoom?.description), style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      )
                    else if (errorMessage != null)
                      _errorBox(errorMessage!)
                    else ...[
                      _missionSummaryCard(currentRoom),
                      if (currentRoom?.status != 'SETTLED') ...[
                        const SizedBox(height: 16),
                        _ruleCard(),
                      ],
                      if (currentRoom?.status == 'IN_PROGRESS') ...[
                        const SizedBox(height: 16),
                        _todayStatusCard(currentRoom),
                        const SizedBox(height: 16),
                        _myStatusCard(),
                      ],
                      const SizedBox(height: 16),
                      _memberPreviewCard(),
                      if (currentRoom?.status != 'SETTLED') ...[
                        const SizedBox(height: 16),
                        _inviteCard(currentRoom),
                      ],
                      const SizedBox(height: 96),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!isLoading && currentRoom != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
              child: _bottomActions(currentRoom),
            ),
        ],
      ),
    );
  }

  // ─── 미션 요약 카드 ────────────────────────────────────────────

  Widget _missionSummaryCard(RoomDetailModel? r) {
    if (r == null) return const SizedBox.shrink();
    final type = r.proofFrequencyType;
    final period = (r.missionStartDate != null && r.missionEndDate != null)
        ? '${_formatDate(r.missionStartDate)} ~ ${_formatDate(r.missionEndDate)}'
        : '미션 시작 전';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('미션 요약',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          _summaryRow(Icons.calendar_today_outlined, '진행 기간', period),
          const SizedBox(height: 10),
          _summaryRow(Icons.track_changes, '인증 방식',
              UiMappers.frequencyGoalLabel(type, r.requiredProofCount)),
          const SizedBox(height: 10),
          _summaryRow(Icons.check_circle_outline, '성공 기준',
              UiMappers.successRuleLabel(r.targetRate)),
          const SizedBox(height: 10),
          _summaryRow(Icons.account_balance_wallet_outlined, '내 예치금',
              UiMappers.point(r.stakePoint)),
          const SizedBox(height: 10),
          _summaryRow(Icons.savings_outlined, '총 예치금',
              UiMappers.point(r.potPoint)),
          const SizedBox(height: 10),
          _summaryRow(Icons.people_outline, '참여 인원',
              '${r.currentMemberCount}/${r.maxMembers}명'),
          const SizedBox(height: 10),
          _summaryRow(Icons.access_time, '인증 마감',
              UiMappers.deadlineLabel(type, r.deadlineTime)),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  // ─── 이 방의 룰 카드 ───────────────────────────────────────────

  Widget _ruleCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text('이 방의 룰',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            UiMappers.confirmNoticeText,
            UiMappers.penaltyNoticeText,
            UiMappers.bonusNoticeText,
          ].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
                  Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(UiMappers.virtualPointNoticeText,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  // ─── 오늘/이번 주 인증 현황 카드 ─────────────────────────────────

  Widget _todayStatusCard(RoomDetailModel? currentRoom) {
    final required = currentRoom?.requiredProofCount ?? 0;
    final type = currentRoom?.proofFrequencyType ?? 'DAILY';
    final title = UiMappers.currentPeriodTitle(type);
    final deadlineText = UiMappers.deadlineLabel(type, currentRoom?.deadlineTime ?? '23:00');

    if (todayStatus == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.access_time, color: Colors.blue.shade100, size: 18),
            const SizedBox(width: 4),
            Text(deadlineText, style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _whiteStat('0', '제출')),
            const SizedBox(width: 12),
            Expanded(child: _whiteStat('0', '확인')),
            const SizedBox(width: 12),
            Expanded(child: _whiteStat('$required', '남은 제출')),
          ]),
          const SizedBox(height: 16),
          Text('미션 기간이 시작되면 제출 현황이 표시됩니다.', style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
        ]),
      );
    }

    final confirmed = _asInt(todayStatus?['myStatus']?['confirmedCount']) ?? 0;
    final submitted = _asInt(todayStatus?['myStatus']?['submittedCount']) ?? 0;
    final remaining = (required - confirmed).clamp(0, required);
    return Container(
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(Icons.access_time, color: Colors.blue.shade100, size: 18),
          const SizedBox(width: 4),
          Text(deadlineText, style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _whiteStat('$submitted', '제출')),
          const SizedBox(width: 12),
          Expanded(child: _whiteStat('$confirmed', '확인')),
          const SizedBox(width: 12),
          Expanded(child: _whiteStat('$remaining', '남은 제출')),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: required > 0 ? (confirmed / required).clamp(0.0, 1.0) : 0.0,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          remaining == 0 ? '이번 기간 목표 달성!' : '확인 $confirmed / 목표 $required',
          style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
        ),
      ]),
    );
  }

  Widget _whiteStat(String value, String label) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
        ]),
      );

  // ─── 내 인증 현황 카드 ─────────────────────────────────────────

  Widget _myStatusCard() {
    final myStatus = todayStatus?['myStatus'];
    final submitted = _asInt(myStatus?['submittedCount']) ?? 0;
    final confirmed = _asInt(myStatus?['confirmedCount']) ?? 0;
    final remainingSubmit = _asInt(myStatus?['remainingSubmitCount']) ?? (room?.requiredProofCount ?? 0);
    final remainingConfirm = _asInt(myStatus?['remainingConfirmCount']) ?? (room?.requiredProofCount ?? 0);
    final status = (myStatus?['progressStatus'] ?? 'NEED_SUBMIT').toString();
    final description = UiMappers.proofProgressDescription(status);

    // 전체 미션 목표 계산
    final r = room;
    final totalRequired = r == null ? 0
        : (r.proofFrequencyType == 'WEEKLY'
            ? (r.durationDays ~/ 7) * r.requiredProofCount
            : r.durationDays * r.requiredProofCount);
    final requiredSuccess = (totalRequired * 0.8).ceil();
    final progressValue = requiredSuccess > 0
        ? (confirmed / requiredSuccess).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('내 인증 현황', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: UiMappers.proofProgressColor(status), borderRadius: BorderRadius.circular(12)),
            child: Text(UiMappers.proofProgressLabel(status), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox('$submitted', '제출', const Color(0xFF3B82F6))),
          const SizedBox(width: 10),
          Expanded(child: _buildStatBox('$confirmed', '확인', const Color(0xFF22C55E))),
          const SizedBox(width: 10),
          Expanded(child: _buildStatBox('$remainingSubmit', '남은 제출', const Color(0xFFF97316))),
          const SizedBox(width: 10),
          Expanded(child: _buildStatBox('$remainingConfirm', '남은 확인', const Color(0xFF9CA3AF))),
        ]),
        if (totalRequired > 0) ...[
          const SizedBox(height: 14),
          Row(children: [
            const Text('전체 목표', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const Spacer(),
            Text('$confirmed / $requiredSuccess회', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: UiMappers.proofProgressColor(status))),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(UiMappers.proofProgressColor(status)),
              minHeight: 8,
            ),
          ),
        ],
      ]),
    );
  }

  // ─── 멤버별 현황 카드 ──────────────────────────────────────────

  Widget _memberPreviewCard() {
    final todayMembers = todayStatus?['members'] as List<dynamic>?;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          const Text('멤버별 현황', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/rooms/${widget.roomId}/members'),
            child: const Text('전체보기', style: TextStyle(fontSize: 14, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        if (todayMembers != null && todayMembers.isNotEmpty)
          ...todayMembers.take(3).map((member) {
            final m = member as Map<String, dynamic>;
            final nickname = m['nickname']?.toString() ?? '알 수 없음';
            final submitted = _asInt(m['submittedCount']) ?? 0;
            final confirmed = _asInt(m['confirmedCount']) ?? 0;
            final statusStr = (m['progressStatus'] ?? m['expectedResult'] ?? m['status'] ?? 'NEED_SUBMIT').toString();
            final role = m['role']?.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMemberCard(
                UiMappers.initialFromName(nickname),
                nickname,
                role == 'OWNER' ? '방장' : null,
                '제출 $submitted · 확인 $confirmed',
                UiMappers.proofProgressLabel(statusStr),
                UiMappers.proofProgressColor(statusStr),
              ),
            );
          })
        else if (members.isEmpty)
          const Text('아직 멤버 정보가 없습니다.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)))
        else
          ...members.take(3).map((m) {
                final statusColor = m.status == 'SUCCESS'
                    ? const Color(0xFF22C55E)
                    : m.status == 'FAILED'
                        ? const Color(0xFFEF4444)
                        : m.status == 'STAKED'
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF9CA3AF);
                final statsText = m.status == 'SUCCESS'
                    ? '미션 성공'
                    : m.status == 'FAILED'
                        ? '미션 실패'
                        : '미션 시작 전';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMemberCard(
                    UiMappers.initialFromName(m.nickname),
                    m.nickname,
                    m.role == 'OWNER' ? '방장' : null,
                    statsText,
                    UiMappers.memberStatusLabel(m.status),
                    statusColor,
                  ),
                );
              }),
      ]),
    );
  }

  // ─── 초대 카드 (기존 유지) ────────────────────────────────────

  Widget _inviteCard(RoomDetailModel? currentRoom) {
    final code = currentRoom?.inviteCode;
    final token = currentRoom?.inviteLinkToken;
    if (code == null && token == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (code != null)
            Row(
              children: [
                const Text('초대코드', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(code, style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
                ),
                GestureDetector(
                  onTap: () => _copyText(code, '초대코드가 복사되었습니다.'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(6)),
                    child: const Text('코드 복사', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          if (code != null && token != null) const SizedBox(height: 10),
          if (token != null)
            Row(
              children: [
                const Text('초대링크', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('/invite/$token', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF))),
                ),
                GestureDetector(
                  onTap: () => _copyText(_buildInviteLink(token), '초대링크가 복사되었습니다.'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(6)),
                    child: const Text('링크 복사', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _buildInviteLink(String inviteLinkToken) {
    if (inviteLinkToken.isEmpty) return '';
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      return '${base.origin}/#/invite/$inviteLinkToken';
    }
    // Android/iOS 앱 환경: file:// 스킴이라 origin 호출 불가
    // deep link 미구현 상태이므로 경로 형태로 복사 (crash 방지)
    return '/invite/$inviteLinkToken';
  }

  Future<void> _copyText(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ─── 하단 액션 (기존 유지) ────────────────────────────────────

  Widget _bottomActions(RoomDetailModel room) {
    final currentUserId = ref.read(authControllerProvider).currentUser?.id;
    final myMember = currentUserId == null ? null : _findMemberByUserId(currentUserId);
    final alreadyStaked = myMember?.status == 'STAKED';

    if (room.status == 'RECRUITING') {
      final button = alreadyStaked
          ? SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('예치금 납부 완료', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isActionLoading ? null : stakeRoom,
                style: _primaryStyle(),
                child: Text(isActionLoading ? '처리 중...' : '예치금 납부하기', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            alreadyStaked ? '다른 멤버 예치 대기 중이에요' : '예치금을 내야 미션에 참여할 수 있어요',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          button,
        ],
      );
    }
    if (room.status == 'READY' && room.myRole == 'OWNER') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('모두 예치 완료! 미션을 시작해 주세요', style: TextStyle(fontSize: 13, color: Color(0xFF22C55E), fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isActionLoading ? null : startRoom,
              style: _primaryStyle(),
              child: Text(isActionLoading ? '처리 중...' : '미션 시작하기', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }
    if (room.status == 'READY') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('방장이 미션을 시작하면 인증을 올릴 수 있어요', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('시작 대기 중', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }
    if (room.status == 'SETTLED') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.push('/rooms/${widget.roomId}/settlement'),
          style: _primaryStyle(),
          child: const Text('정산 결과 보기', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }
    if (_canSettle(room)) {
      return Row(children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isActionLoading ? null : _settleRoom,
            style: _primaryStyle(),
            child: Text(isActionLoading ? '처리 중...' : '정산하기', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go('/rooms/${widget.roomId}/proofs'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('인증 확인하기', style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]);
    }
    return Row(children: [
      Expanded(child: ElevatedButton.icon(onPressed: () => context.go('/rooms/${widget.roomId}/submit-proof'), icon: const Icon(Icons.upload), label: const Text('인증 올리기', style: TextStyle(fontWeight: FontWeight.w600)), style: _primaryStyle())),
      const SizedBox(width: 12),
      Expanded(child: OutlinedButton.icon(onPressed: () => context.go('/rooms/${widget.roomId}/proofs'), icon: const Icon(Icons.check_circle_outline), label: const Text('인증 확인하기', style: TextStyle(fontWeight: FontWeight.w600)), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3B82F6), side: const BorderSide(color: Color(0xFF3B82F6)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]);
  }

  ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0);

  Widget _buildStatBox(String value, String label, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ]),
      );

  Widget _buildMemberCard(
    String initial,
    String name,
    String? role,
    String stats,
    String status,
    Color statusColor,
  ) {
    return Row(
      children: [
        Container(width: 4, height: 44, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          child: Center(
            child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  if (role != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(4)),
                      child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(stats, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
          child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _errorBox(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA))),
        child: Text(message, style: const TextStyle(color: Color(0xFFEF4444))),
      );

  RoomMemberModel? _findMemberByUserId(int userId) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  int? _asInt(dynamic value) => value is num ? value.toInt() : null;
}
