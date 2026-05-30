import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../models/room_model.dart';
import '../ui/checkmate_ui.dart';

class RoomDashboardScreen extends ConsumerStatefulWidget {
  const RoomDashboardScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<RoomDashboardScreen> createState() => _RoomDashboardScreenState();
}

class _RoomDashboardScreenState extends ConsumerState<RoomDashboardScreen> {
  late Future<_RoomDashboardData> future;
  bool actionLoading = false;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_RoomDashboardData> _load() async {
    final roomService = ref.read(roomServiceProvider);
    final room = await roomService.getRoomDetail(widget.roomId);
    Map<String, dynamic>? today;
    Map<String, dynamic>? stats;

    if (room.status == 'IN_PROGRESS' || room.status == 'SETTLED') {
      try {
        today = await roomService.getTodayStatus(widget.roomId);
      } catch (_) {}
      try {
        stats = await roomService.getMemberStats(widget.roomId);
      } catch (_) {}
    }

    return _RoomDashboardData(room: room, today: today, stats: stats);
  }

  void _refresh() {
    setState(() => future = _load());
  }

  Future<void> _stakeRoom() async {
    setState(() => actionLoading = true);
    try {
      await ref.read(roomServiceProvider).stakeRoom(widget.roomId);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> _startRoom() async {
    setState(() => actionLoading = true);
    try {
      await ref.read(roomServiceProvider).startRoom(widget.roomId);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RoomDashboardData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CMPage(child: Center(child: CircularProgressIndicator(color: CMColors.blue)));
        }
        if (snapshot.hasError) {
          return CMPage(child: CMErrorView(message: '방 정보를 불러오지 못했어요.', onRetry: _refresh));
        }

        final data = snapshot.data!;
        final room = data.room;

        return CMPage(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 102),
          bottom: room.status == 'IN_PROGRESS'
              ? _BottomActions(roomId: widget.roomId)
              : null,
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: CMColors.blue,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                CMTopBar(
                  title: room.title,
                  badge: roomStatusText(room.status),
                  onBack: () => context.canPop() ? context.pop() : context.go('/rooms'),
                  actions: [
                    IconButton(
                      onPressed: () => context.push('/rooms/${widget.roomId}/chat'),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: CMColors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (room.status == 'SETTLED')
                  _SettledEntry(room: room)
                else if (room.status != 'IN_PROGRESS')
                  _BeforeStartCard(
                    room: room,
                    loading: actionLoading,
                    onStake: _stakeRoom,
                    onStart: _startRoom,
                  )
                else
                  _ActiveRoomBody(room: room, today: data.today, stats: data.stats),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _ActiveRoomBody extends StatelessWidget {
  const _ActiveRoomBody({required this.room, this.today, this.stats});

  final RoomDetailModel room;
  final Map<String, dynamic>? today;
  final Map<String, dynamic>? stats;

  @override
  Widget build(BuildContext context) {
    final members = (today?['members'] as List<dynamic>? ?? []);
    final statsMembers = (stats?['members'] as List<dynamic>? ?? []);

    final submittedCount = members.fold<int>(0, (sum, e) => sum + readInt((e as Map<String, dynamic>)['submittedCount']));
    final confirmedCount = members.fold<int>(0, (sum, e) => sum + readInt((e as Map<String, dynamic>)['confirmedCount']));
    final waitingCount = (submittedCount - confirmedCount).clamp(0, 999);

    final totalRequired = readInt(stats?['totalRequiredProofCount'], fallback: room.durationDays * room.requiredProofCount);
    final requiredSuccess = readInt(stats?['requiredSuccessCount'], fallback: (totalRequired * room.targetRate / 100).ceil());
    final progressValue = totalRequired == 0 ? 0.0 : (confirmedCount / totalRequired).clamp(0.0, 1.0);

    final myStatus = today?['myStatus'] as Map<String, dynamic>?;
    final mySubmitted = readInt(myStatus?['submittedCount']);
    final myConfirmed = readInt(myStatus?['confirmedCount']);
    final myWaiting = (mySubmitted - myConfirmed).clamp(0, 999);
    final myRemaining = readInt(myStatus?['remainingSubmitCount'], fallback: room.requiredProofCount);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: CMColors.blue.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _WhitePill(label: '오늘의 미션 보드', icon: Icons.flag_rounded),
                  const Spacer(),
                  _WhitePill(label: '${room.deadlineTime} 마감', icon: Icons.timer_rounded),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _MissionMetric(label: '참여 멤버', value: '${room.currentMemberCount}', icon: Icons.groups_rounded)),
                  const SizedBox(width: 9),
                  Expanded(child: _MissionMetric(label: '성공 인정', value: '$confirmedCount', icon: Icons.verified_rounded)),
                  const SizedBox(width: 9),
                  Expanded(child: _MissionMetric(label: '확인 대기', value: '$waitingCount', icon: Icons.hourglass_bottom_rounded)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text('멤버 현황', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Text('$confirmedCount / $totalRequired회', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ...members.take(4).map((e) {
                    final m = e as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Text(
                          initials(readString(m['nickname'])),
                          style: const TextStyle(color: CMColors.blue, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    );
                  }),
                  if (room.currentMemberCount > 4)
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                      child: Text('+${room.currentMemberCount - 4}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
                    child: Text('${(progressValue * 100).round()}% 달성', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CMProgressBar(value: progressValue, color: Colors.white, background: Colors.white.withValues(alpha: 0.22), height: 7),
              const SizedBox(height: 8),
              Text('성공 기준: 전체 인증의 ${room.targetRate}% 이상 · $requiredSuccess회 이상 인정', style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CMCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('오늘 인증 상태', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: CMColors.text)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/rooms/${room.id}/proofs'),
                    child: const Text('인증 피드 보기 ›', style: TextStyle(fontSize: 12, color: CMColors.blue, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatusBox(value: '$mySubmitted', label: '제출', color: CMColors.blue),
                  const SizedBox(width: 8),
                  _StatusBox(value: '$myConfirmed', label: '인정', color: CMColors.green),
                  const SizedBox(width: 8),
                  _StatusBox(value: '$myWaiting', label: '대기', color: CMColors.orange),
                  const SizedBox(width: 8),
                  _StatusBox(value: '$myRemaining', label: '남음', color: CMColors.sub),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('내 누적 인정', style: TextStyle(fontSize: 11, color: CMColors.sub, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('$myConfirmed / $totalRequired회', style: const TextStyle(fontSize: 12, color: CMColors.text, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              CMProgressBar(value: totalRequired == 0 ? 0 : myConfirmed / totalRequired, color: CMColors.blue, height: 7),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CMCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('멤버 진행 미리보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: CMColors.text)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/rooms/${room.id}/members'),
                    child: const Text('전체보기 ›', style: TextStyle(fontSize: 12, color: CMColors.blue, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (statsMembers.isEmpty)
                const Text('아직 멤버 진행 데이터가 없어요.', style: TextStyle(color: CMColors.sub, fontSize: 12))
              else
                ...statsMembers.take(3).map((e) {
                  final m = e as Map<String, dynamic>;
                  final name = readString(m['nickname']);
                  final confirmed = readInt(m['confirmedCount']);
                  final total = readInt(m['totalRequiredProofCount'], fallback: totalRequired);
                  final result = readString(m['expectedResult']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MemberPreviewRow(
                      name: name,
                      role: readString(m['role']),
                      value: total == 0 ? 0 : confirmed / total,
                      countText: '$confirmed / $total',
                      status: memberExpectedText(result),
                      color: statusColor(result),
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoAndInvite(room: room),
      ],
    );
  }
}

class _WhitePill extends StatelessWidget {
  const _WhitePill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(99)),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MissionMetric extends StatelessWidget {
  const _MissionMetric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 64,
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: CMColors.sub, fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _InfoAndInvite extends StatelessWidget {
  const _InfoAndInvite({required this.room});
  final RoomDetailModel room;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CMCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('미션 요약', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: CMColors.text)),
              const SizedBox(height: 12),
              CMInfoRow(icon: Icons.calendar_month_rounded, label: '진행 기간', value: '${formatDate(room.missionStartDate)} ~ ${formatDate(room.missionEndDate)}'),
              CMInfoRow(icon: Icons.timer_rounded, label: '인증 방식', value: proofFrequencyText(room.proofFrequencyType, room.requiredProofCount)),
              CMInfoRow(icon: Icons.check_circle_outline_rounded, label: '성공 기준', value: '인증 ${room.targetRate}% 이상 확인받기'),
              CMInfoRow(icon: Icons.account_balance_wallet_rounded, label: '내 예치금', value: formatPoint(room.stakePoint)),
              CMInfoRow(icon: Icons.savings_rounded, label: '총 예치금', value: formatPoint(room.potPoint)),
              CMInfoRow(icon: Icons.groups_rounded, label: '참여 인원', value: '${room.currentMemberCount}/${room.maxMembers}명'),
              CMInfoRow(icon: Icons.schedule_rounded, label: '인증 마감', value: '매일 ${room.deadlineTime}까지'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CMCard(
          background: const Color(0xFFF8FBFF),
          borderColor: const Color(0xFFCFE1FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('이 방의 룰', style: TextStyle(fontSize: 15, color: CMColors.blue, fontWeight: FontWeight.w900)),
              SizedBox(height: 12),
              _RuleText('매일 정해진 횟수만큼 인증을 올려야 해요.'),
              _RuleText('다른 멤버의 인증을 확인하고 인정해 주세요.'),
              _RuleText('확인받은 인증만 성공으로 인정돼요.'),
              SizedBox(height: 10),
              Text('현재 포인트는 서비스 내 가상 포인트입니다.', style: TextStyle(fontSize: 10, color: CMColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CMCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('친구 초대하고 함께 성공해요!', style: TextStyle(fontSize: 15, color: CMColors.text, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('친구를 초대하고 함께 미션을 완주해요.', style: TextStyle(fontSize: 11, color: CMColors.sub)),
              const SizedBox(height: 16),
              _CopyRow(label: '초대코드', value: room.inviteCode ?? '-'),
              const SizedBox(height: 10),
              _CopyRow(label: '초대링크', value: room.inviteLinkToken == null ? '-' : 'https://checkmate.app/invite/${room.inviteLinkToken}'),
              const SizedBox(height: 14),
              CMPrimaryButton(
                label: '초대 링크 공유하기',
                icon: Icons.share_rounded,
                onPressed: () async {
                  final text = room.inviteLinkToken == null ? (room.inviteCode ?? '') : 'https://checkmate.app/invite/${room.inviteLinkToken}';
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 정보가 복사됐어요.')));
                  }
                },
                height: 44,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _SettledEntry extends StatelessWidget {
  const _SettledEntry({required this.room});
  final RoomDetailModel room;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CMGradientCard(
          colors: const [Color(0xFF4F46E5), CMColors.blue],
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    CMPill(label: '미션 종료', color: Colors.white, background: Color(0x33FFFFFF)),
                    SizedBox(height: 18),
                    Text('정산이 완료되었어요!', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    Text('미션 기간 동안 고생했어요.\n최종 결과를 확인해 보세요.', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 12, height: 1.45)),
                  ],
                ),
              ),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 38),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CMCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  _SettledMini(label: '참여 인원', value: '${room.currentMemberCount}/${room.maxMembers}명', icon: Icons.groups_rounded),
                  _DividerMini(),
                  _SettledMini(label: '총 예치금', value: formatPoint(room.potPoint), icon: Icons.savings_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SettledMini(label: '인증 방식', value: proofFrequencyText(room.proofFrequencyType, room.requiredProofCount), icon: Icons.timer_rounded),
                  _DividerMini(),
                  _SettledMini(label: '성공 기준', value: '인증 ${room.targetRate}% 이상', icon: Icons.check_circle_outline_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CMCard(
          background: const Color(0xFFF8FBFF),
          borderColor: const Color(0xFFCFE1FF),
          child: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: CMColors.blue, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '정산 결과 화면에서 성공/실패 인원, 보상 포인트, 환불 금액을 확인할 수 있어요.',
                  style: TextStyle(color: CMColors.text, fontSize: 12, height: 1.45, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        CMPrimaryButton(
          label: '정산 결과 보기',
          icon: Icons.emoji_events_rounded,
          onPressed: () => context.push('/rooms/${room.id}/settlement'),
        ),
      ],
    );
  }
}

class _SettledMini extends StatelessWidget {
  const _SettledMini({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: CMColors.muted, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: CMColors.sub, fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CMColors.text, fontSize: 12, fontWeight: FontWeight.w900)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DividerMini extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, margin: const EdgeInsets.symmetric(horizontal: 10), color: CMColors.line);
  }
}

class _BeforeStartCard extends StatelessWidget {
  const _BeforeStartCard({
    required this.room,
    required this.loading,
    required this.onStake,
    required this.onStart,
  });

  final RoomDetailModel room;
  final bool loading;
  final VoidCallback onStake;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isOwner = room.myRole == 'OWNER';
    return Column(
      children: [
        CMGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(roomStatusText(room.status), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Text(room.status == 'READY' ? '시작 준비가 끝났어요!' : '멤버를 모집 중이에요!', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('${room.currentMemberCount}/${room.maxMembers}명 참여 · 예치금 ${formatPoint(room.stakePoint)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InfoAndInvite(room: room),
        const SizedBox(height: 18),
        if (room.status == 'RECRUITING')
          CMPrimaryButton(label: '예치금 납부하기', icon: Icons.account_balance_wallet_rounded, onPressed: onStake, loading: loading)
        else if (room.status == 'READY' && isOwner)
          CMPrimaryButton(label: '미션 시작하기', icon: Icons.play_arrow_rounded, onPressed: onStart, loading: loading)
        else if (room.status == 'READY')
          const CMCard(child: Text('방장이 미션을 시작하면 다음 날부터 인증이 시작돼요.', style: TextStyle(color: CMColors.sub))),
      ],
    );
  }
}


class _MemberPreviewRow extends StatelessWidget {
  const _MemberPreviewRow({
    required this.name,
    required this.role,
    required this.value,
    required this.countText,
    required this.status,
    required this.color,
  });

  final String name;
  final String role;
  final double value;
  final String countText;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CMAvatar(label: name, color: color == CMColors.sub ? CMColors.blue : color, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: CMColors.text)),
                if (role == 'OWNER') ...[
                  const SizedBox(width: 6),
                  const CMPill(label: '방장', color: CMColors.blue, background: Color(0xFFDBEAFE), fontSize: 8, padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3)),
                ],
              ]),
              const SizedBox(height: 8),
              CMProgressBar(value: value, color: CMColors.blue),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(countText, style: const TextStyle(fontSize: 11, color: CMColors.text, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        CMPill(label: status, color: color, background: color.withValues(alpha: 0.12), fontSize: 9),
      ],
    );
  }
}

class _RuleText extends StatelessWidget {
  const _RuleText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text('• $text', style: const TextStyle(fontSize: 11, color: CMColors.text, height: 1.35)),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(11), border: Border.all(color: CMColors.line)),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: CMColors.sub, fontWeight: FontWeight.w700)),
          const Spacer(),
          Flexible(
            child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: CMColors.text, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('복사됐어요.')));
            },
            child: const CMPill(label: '복사', color: CMColors.blue, background: Color(0xFFDBEAFE), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.roomId});
  final int roomId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: CMColors.line))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: CMPrimaryButton(
                label: '인증 올리기',
                icon: Icons.upload_rounded,
                onPressed: () => context.push('/rooms/$roomId/submit-proof'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CMOutlineButton(
                label: '인증 확인하기',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => context.push('/rooms/$roomId/proofs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomDashboardData {
  const _RoomDashboardData({
    required this.room,
    this.today,
    this.stats,
  });

  final RoomDetailModel room;
  final Map<String, dynamic>? today;
  final Map<String, dynamic>? stats;
}
