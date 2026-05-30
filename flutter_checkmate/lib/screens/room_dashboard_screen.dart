
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/ui_mappers.dart';
import '../models/room_model.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

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
    setState(() { isLoading = true; errorMessage = null; });
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

  // ─── 상태 헬퍼 ────────────────────────────────────────────────

  int? _asInt(dynamic v) => v is num ? v.toInt() : null;

  String _memberStatusStr(Map m) =>
      (m['progressStatus'] ?? m['expectedResult'] ?? m['status'] ?? 'NEED_SUBMIT').toString();

  String _progressPillLabel(String status) {
    switch (status) {
      case 'SUCCESS': return '성공 기준 충족';
      case 'WAITING_CONFIRM': return '멤버 확인 필요';
      case 'NEED_SUBMIT': return '인증 제출 필요';
      case 'MISSED': return '마감 실패';
      default: return UiMappers.proofProgressLabel(status);
    }
  }

  String _progressMessage(String status) {
    switch (status) {
      case 'SUCCESS': return '오늘도 목표 달성! 수고했어요';
      case 'WAITING_CONFIRM': return '멤버 확인을 기다리고 있어요';
      case 'NEED_SUBMIT': return '아직 오늘 인증이 제출되지 않았어요';
      case 'MISSED': return '오늘 마감까지 인증하지 못했어요';
      default: return UiMappers.proofProgressDescription(status);
    }
  }

  String _myActionDescription(String status) {
    switch (status) {
      case 'SUCCESS': return '오늘 인증이 성공으로 인정됐어요.';
      case 'WAITING_CONFIRM': return '오늘 인증은 제출했어요. 이제 멤버 확인을 받으면 성공으로 인정돼요.';
      case 'NEED_SUBMIT': return '아직 오늘 인증을 제출하지 않았어요.';
      case 'MISSED': return '오늘 인증 마감 시간이 지났어요.';
      default: return '';
    }
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentRoom = room;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 헤더 ────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, size: 22),
                          color: AppColors.primary,
                          onPressed: () => context.push('/rooms/${widget.roomId}/chat'),
                        ),
                        const SizedBox(width: 4),
                        if (currentRoom != null)
                          StatusBadge(text: UiMappers.statusLabel(currentRoom.status), status: currentRoom.status),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentRoom?.title ?? '',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          if ((currentRoom?.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              UiMappers.roomDescriptionFallback(currentRoom?.title ?? '', currentRoom?.description),
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(height: 1, color: AppColors.borderLight),
          // ─── 본문 ─────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    else if (errorMessage != null)
                      _errorBox(errorMessage!)
                    else if (currentRoom != null) ...[
                      _buildStatusContent(currentRoom),
                      const SizedBox(height: 100),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // ─── 하단 버튼 ────────────────────────────────────────────
          if (!isLoading && currentRoom != null)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: _bottomActions(currentRoom),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 상태별 본문 분기 ──────────────────────────────────────────

  Widget _buildStatusContent(RoomDetailModel r) {
    switch (r.status) {
      case 'IN_PROGRESS':
        return Column(children: [
          _missionBoardHero(r),
          const SizedBox(height: 16),
          _myActionCard(),
          const SizedBox(height: 16),
          _memberPreviewCard(),
          const SizedBox(height: 16),
          _missionSummaryCard(r),
          const SizedBox(height: 16),
          _ruleCard(r),
          const SizedBox(height: 16),
          _inviteCard(r),
        ]);
      case 'RECRUITING':
        return Column(children: [
          _recruitingHeroCard(r),
          const SizedBox(height: 16),
          _memberPreviewCard(),
          const SizedBox(height: 16),
          _missionSummaryCard(r),
          const SizedBox(height: 16),
          _ruleCard(r),
          const SizedBox(height: 16),
          _inviteCard(r),
        ]);
      case 'READY':
        return Column(children: [
          _readyHeroCard(r),
          const SizedBox(height: 16),
          _memberPreviewCard(),
          const SizedBox(height: 16),
          _missionSummaryCard(r),
          const SizedBox(height: 16),
          _ruleCard(r),
        ]);
      case 'SETTLED':
        return Column(children: [
          _settledHeroCard(),
          const SizedBox(height: 16),
          _memberPreviewCard(),
          const SizedBox(height: 16),
          _missionSummaryCard(r),
        ]);
      default:
        return Column(children: [
          _missionSummaryCard(r),
          const SizedBox(height: 16),
          _ruleCard(r),
          const SizedBox(height: 16),
          _memberPreviewCard(),
        ]);
    }
  }

  // ─── Mission Board Hero (IN_PROGRESS) ────────────────────────

  Widget _missionBoardHero(RoomDetailModel r) {
    final type = r.proofFrequencyType;
    final boardTitle = type == 'WEEKLY' ? '이번 주 미션 보드' : '오늘의 미션 보드';
    final deadlineText = UiMappers.deadlineLabel(type, r.deadlineTime);

    final memberList = (todayStatus?['members'] as List?) ?? [];
    final totalMembers = r.currentMemberCount;
    final totalConfirmed = memberList.fold<int>(0, (s, m) => s + (_asInt((m as Map)['confirmedCount']) ?? 0));
    final totalSubmitted = memberList.fold<int>(0, (s, m) => s + (_asInt((m as Map)['submittedCount']) ?? 0));
    final waitingConfirm = (totalSubmitted - totalConfirmed).clamp(0, totalSubmitted);
    final successMemberCount = memberList.where((m) => _memberStatusStr(m as Map) == 'SUCCESS').length;
    final progressValue = totalMembers > 0 ? (successMemberCount / totalMembers).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -30, top: -30,
              child: Container(width: 130, height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
            Positioned(left: -10, bottom: -20,
              child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 row: pill + deadline
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                        child: Text(boardTitle, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, color: Colors.white.withValues(alpha: 0.85), size: 12),
                            const SizedBox(width: 4),
                            Text(deadlineText, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 3개 핵심 메트릭
                  Row(
                    children: [
                      _boardStat('$totalMembers명', '참여 멤버'),
                      const SizedBox(width: 20),
                      _boardStat('$totalConfirmed건', '성공 인정'),
                      const SizedBox(width: 20),
                      _boardStat('$waitingConfirm건', '확인 대기'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 성공률 프로그레스
                  Row(
                    children: [
                      Text('성공 기준 충족', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('$successMemberCount / $totalMembers명', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '성공 인정은 멤버 확인을 받은 인증만 계산돼요.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── 내 오늘 액션 카드 ────────────────────────────────────────

  Widget _myActionCard() {
    final myStatus = todayStatus?['myStatus'];
    final submitted = _asInt(myStatus?['submittedCount']) ?? 0;
    final confirmed = _asInt(myStatus?['confirmedCount']) ?? 0;
    final remainingSubmit = _asInt(myStatus?['remainingSubmitCount']) ?? (room?.requiredProofCount ?? 0);
    final waiting = (submitted - confirmed).clamp(0, submitted);
    final status = (myStatus?['progressStatus'] ?? 'NEED_SUBMIT').toString();
    final pillLabel = _progressPillLabel(status);
    final pillColor = UiMappers.proofProgressColor(status);
    final description = _myActionDescription(status);

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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('내 오늘 액션', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pillColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: pillColor.withValues(alpha: 0.3)),
                ),
                child: Text(pillLabel, style: TextStyle(color: pillColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _statBox('$submitted', '인증 제출', AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$confirmed', '성공 인정', AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$waiting', '확인 대기', AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$remainingSubmit', '더 필요', AppColors.textMuted)),
          ]),
          if (totalRequired > 0) ...[
            const SizedBox(height: 16),
            Row(children: [
              const Text('전체 목표', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              Text('$confirmed / $requiredSuccess회', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pillColor)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(pillColor),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 멤버 진행 현황 Preview ───────────────────────────────────

  Widget _memberPreviewCard() {
    final todayMembers = todayStatus?['members'] as List<dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SectionHeader(
            title: '멤버 진행 현황',
            trailing: GestureDetector(
              onTap: () => context.go('/rooms/${widget.roomId}/members'),
              child: const Text('전체보기', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          if (todayMembers != null && todayMembers.isNotEmpty)
            ...todayMembers.take(4).map((member) {
              final m = member as Map<String, dynamic>;
              final nickname = m['nickname']?.toString() ?? '알 수 없음';
              final statusStr = _memberStatusStr(m);
              final role = m['role']?.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _memberProgressRow(nickname, role, statusStr),
              );
            })
          else if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('아직 멤버 정보가 없어요.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            )
          else
            ...members.take(4).map((m) {
              final isSettled = room?.status == 'SETTLED';
              final statusStr = m.status == 'SUCCESS' ? 'SUCCESS'
                  : m.status == 'FAILED' ? 'FAILED'
                  : m.status == 'STAKED' ? 'WAITING_CONFIRM'
                  : 'NEED_SUBMIT';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: isSettled
                    ? _settledMemberRow(m.nickname, m.role, statusStr)
                    : _memberProgressRow(m.nickname, m.role, statusStr),
              );
            }),
        ],
      ),
    );
  }

  Widget _memberProgressRow(String nickname, String? role, String status) {
    final pillColor = UiMappers.proofProgressColor(status);
    final pillLabel = _progressPillLabel(status);
    final message = _progressMessage(status);
    final softBg = pillColor.withValues(alpha: 0.1);

    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: softBg,
            shape: BoxShape.circle,
            border: Border.all(color: pillColor.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(UiMappers.initialFromName(nickname), style: TextStyle(color: pillColor, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(nickname, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                  if (role == 'OWNER') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(4)),
                      child: const Text('방장', style: TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
      ],
    );
  }

  Widget _settledMemberRow(String nickname, String? role, String status) {
    final isSuccess = status == 'SUCCESS';
    final pillLabel = isSuccess ? '성공' : '실패';
    final pillColor = isSuccess ? AppColors.successDark : AppColors.error;
    final pillBg = isSuccess ? AppColors.successSoft : AppColors.errorSoft;
    final avatarBg = isSuccess ? AppColors.successSoft : AppColors.errorSoft;

    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
          child: Center(
            child: Text(UiMappers.initialFromName(nickname), style: TextStyle(color: pillColor, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Flexible(child: Text(nickname, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
              if (role == 'OWNER') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(4)),
                  child: const Text('방장', style: TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(999)),
          child: Text(pillLabel, style: TextStyle(color: pillColor, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
      ],
    );
  }

  // ─── 상태별 Hero 카드 ─────────────────────────────────────────

  Widget _recruitingHeroCard(RoomDetailModel r) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(
          children: [
            Positioned(right: -30, top: -30, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
            Positioned(right: 40, bottom: -40, child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
                      child: const Text('모집 중', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Icon(Icons.group_add_outlined, color: Colors.white.withValues(alpha: 0.6), size: 22),
                  ]),
                  const SizedBox(height: 14),
                  const Text('멤버를 기다리고 있어요', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('예치금을 납부하면 미션 준비가 완료돼요', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(children: [
                    _heroStat('${r.currentMemberCount}/${r.maxMembers}', '참여 인원'),
                    const SizedBox(width: 28),
                    _heroStat(UiMappers.point(r.stakePoint), '예치금'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readyHeroCard(RoomDetailModel r) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.successDark, AppColors.success], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(
          children: [
            Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
            Positioned(right: 50, bottom: -35, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
                      child: const Text('시작 대기', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Icon(Icons.emoji_events_outlined, color: Colors.white.withValues(alpha: 0.65), size: 24),
                  ]),
                  const SizedBox(height: 14),
                  const Text('전원 예치 완료! 🎉', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('방장이 시작하면 내일부터 인증을 올릴 수 있어요', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(children: [
                    _heroStat('${r.currentMemberCount}명', '참여 인원'),
                    const SizedBox(width: 28),
                    _heroStat(UiMappers.point(r.potPoint), '총 예치금'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settledHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -25, top: -35, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
            Positioned(left: -10, bottom: -25, child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                          child: const Text('미션 종료', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 14),
                        const Text('정산 완료', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('정산이 완료된 방이에요.\n아래에서 최종 결과를 확인해 보세요.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_events_rounded, size: 40, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
      ],
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '미션 요약'),
          const SizedBox(height: 16),
          _summaryRow(Icons.calendar_today_outlined, '진행 기간', period),
          const SizedBox(height: 10),
          _summaryRow(Icons.track_changes, '인증 방식', UiMappers.frequencyGoalLabel(type, r.requiredProofCount)),
          const SizedBox(height: 10),
          _summaryRow(Icons.check_circle_outline, '성공 기준', UiMappers.successRuleLabel(r.targetRate)),
          const SizedBox(height: 10),
          _summaryRow(Icons.account_balance_wallet_outlined, '내 예치금', UiMappers.point(r.stakePoint)),
          const SizedBox(height: 10),
          _summaryRow(Icons.savings_outlined, '총 예치금', UiMappers.point(r.potPoint)),
          const SizedBox(height: 10),
          _summaryRow(Icons.people_outline, '참여 인원', '${r.currentMemberCount}/${r.maxMembers}명'),
          const SizedBox(height: 10),
          _summaryRow(Icons.access_time, '인증 마감', UiMappers.deadlineLabel(type, r.deadlineTime)),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  // ─── 이 방의 룰 ────────────────────────────────────────────────

  Widget _ruleCard(RoomDetailModel r) {
    final type = r.proofFrequencyType;
    final periodWord = type == 'WEEKLY' ? '매주' : '매일';
    final confirmRule = '확인받은 인증만 성공으로 인정돼요.';
    final submitRule = '$periodWord 정해진 횟수만큼 인증을 올려야 해요.';
    final checkRule = '다른 멤버의 인증을 확인하고 인정해 주세요.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.primary),
            SizedBox(width: 8),
            Text('이 방의 룰', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ]),
          const SizedBox(height: 12),
          ...[submitRule, checkRule, confirmRule].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(UiMappers.virtualPointNoticeText, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ─── 초대 카드 ────────────────────────────────────────────────

  Widget _inviteCard(RoomDetailModel? currentRoom) {
    final code = currentRoom?.inviteCode;
    final token = currentRoom?.inviteLinkToken;
    if (code == null && token == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.link, size: 16, color: AppColors.primary),
            SizedBox(width: 8),
            Text('친구 초대', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ]),
          const SizedBox(height: 12),
          if (code != null)
            Row(children: [
              const Text('초대코드', style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(child: Text(code, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: () => _copyText(code, '초대코드가 복사되었습니다.'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(8)),
                  child: const Text('복사', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          if (code != null && token != null) const SizedBox(height: 10),
          if (token != null)
            Row(children: [
              const Text('초대링크', style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(child: Text('/invite/$token', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark))),
              GestureDetector(
                onTap: () => _copyText(_buildInviteLink(token), '초대링크가 복사되었습니다.'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(8)),
                  child: const Text('복사', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
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
    return '/invite/$inviteLinkToken';
  }

  Future<void> _copyText(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ─── 하단 액션 ────────────────────────────────────────────────

  Widget _bottomActions(RoomDetailModel room) {
    final currentUserId = ref.read(authControllerProvider).currentUser?.id;
    final myMember = currentUserId == null ? null : _findMemberByUserId(currentUserId);
    final alreadyStaked = myMember?.status == 'STAKED';

    if (room.status == 'RECRUITING') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            alreadyStaked ? '다른 멤버 예치 대기 중이에요' : '예치금을 내야 미션에 참여할 수 있어요',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          alreadyStaked
              ? SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('예치금 납부 완료', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isActionLoading ? null : stakeRoom,
                    style: _primaryStyle(),
                    child: Text(isActionLoading ? '처리 중...' : '예치금 납부하기', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
        ],
      );
    }

    if (room.status == 'READY' && room.myRole == 'OWNER') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('모두 예치 완료! 미션을 시작해 주세요', style: TextStyle(fontSize: 13, color: AppColors.successDark, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isActionLoading ? null : startRoom,
              style: _primaryStyle(),
              child: Text(isActionLoading ? '처리 중...' : '미션 시작하기', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      );
    }

    if (room.status == 'READY') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('방장이 미션을 시작하면 인증을 올릴 수 있어요', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('시작 대기 중', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }

    if (room.status == 'SETTLED') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/rooms/${widget.roomId}/settlement'),
          icon: const Icon(Icons.emoji_events_rounded, size: 20),
          label: const Text('정산 결과 보기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          style: _primaryStyle(),
        ),
      );
    }

    if (_canSettle(room)) {
      return Row(children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isActionLoading ? null : _settleRoom,
              style: _primaryStyle(),
              child: Text(isActionLoading ? '처리 중...' : '정산하기', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/rooms/${widget.roomId}/proofs'),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('인증 확인하기', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ]);
    }

    // IN_PROGRESS 기본
    return Row(children: [
      Expanded(
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/rooms/${widget.roomId}/submit-proof'),
            icon: const Icon(Icons.upload, size: 18),
            label: const Text('인증 올리기', style: TextStyle(fontWeight: FontWeight.w600)),
            style: _primaryStyle(),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/rooms/${widget.roomId}/proofs'),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('인증 확인하기', style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    ]);
  }

  // ─── 공통 위젯 ────────────────────────────────────────────────

  ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 0,
  );

  Widget _statBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _errorBox(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.errorSoft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );

  RoomMemberModel? _findMemberByUserId(int userId) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }
}
