
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

  Future<void> stakeRoom() async => _runAction(() => ref.read(roomServiceProvider).stakeRoom(widget.roomId));
  Future<void> startRoom() async => _runAction(() => ref.read(roomServiceProvider).startRoom(widget.roomId));

  Future<void> _runAction(Future<RoomDetailModel> Function() action) async {
    setState(() { isActionLoading = true; errorMessage = null; });
    try {
      await action();
      await loadDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
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
                      const SizedBox(height: 16),
                      _ruleCard(),
                      const SizedBox(height: 16),
                      _todayStatusCard(currentRoom),
                      const SizedBox(height: 16),
                      _myStatusCard(),
                      const SizedBox(height: 16),
                      _memberPreviewCard(),
                      const SizedBox(height: 16),
                      _inviteCard(currentRoom),
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
              UiMappers.stakePointLabel(r.stakePoint)),
          const SizedBox(height: 10),
          _summaryRow(Icons.savings_outlined, '총 예치금',
              UiMappers.potPointLabel(r.potPoint)),
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
            '확인 완료된 인증만 성공 기준에 반영돼요.',
            '성공하면 예치금을 돌려받아요.',
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
    final remainLabel = UiMappers.remainingSubmitLabel(type);
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
        Text('확인 완료된 인증만 목표 달성에 반영돼요.', style: TextStyle(color: Colors.blue.shade100, fontSize: 12)),
        const SizedBox(height: 8),
        Text(remaining == 0 ? '목표를 완료했어요!' : '목표까지 $remaining개 남았어요!', style: TextStyle(color: Colors.blue.shade100, fontSize: 14)),
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
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox('$submitted', '제출 완료', const Color(0xFF3B82F6))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox('$confirmed', '확인 완료', const Color(0xFF22C55E))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildStatBox('$remainingSubmit', '남은 제출', const Color(0xFFF97316))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox('$remainingConfirm', '남은 확인', const Color(0xFF9CA3AF))),
        ]),
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
          ...members.take(3).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMemberCard(
                  UiMappers.initialFromName(m.nickname),
                  m.nickname,
                  m.role == 'OWNER' ? '방장' : null,
                  '미션 시작 전 멤버',
                  UiMappers.memberStatusLabel(m.status),
                  m.status == 'STAKED' ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                ),
              )),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.all(14),
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
                  onTap: () => _copyText('${Uri.base.origin}/#/invite/$token', '초대링크가 복사되었습니다.'),
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
          const Text('미션 시작 후 인증 제출이 가능합니다.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 10),
          button,
        ],
      );
    }
    if (room.status == 'READY' && room.myRole == 'OWNER') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('미션 시작 후 인증 제출이 가능합니다.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
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
          const Text('미션 시작 후 인증 제출이 가능합니다.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('방장이 미션을 시작할 때까지 대기 중', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
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
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
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
