import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
import '../models/point_model.dart';
import '../models/room_model.dart';
import '../ui/checkmate_ui.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<_HomeData> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_HomeData> _load() async {
    final rooms = await ref.read(roomServiceProvider).getMyRooms();
    final wallet = await ref.read(pointServiceProvider).getMyWallet();
    final unread = await ref.read(notificationServiceProvider).getUnreadCount();
    return _HomeData(rooms: rooms, wallet: wallet, unreadCount: unread);
  }

  void _refresh() {
    setState(() => future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: future,
      builder: (context, snapshot) {
        return CMPage(
          bottom: CMBottomNav(
            current: 'home',
            onTap: (key) {
              if (key == 'home') context.go('/home');
              if (key == 'rooms') context.go('/rooms');
              if (key == 'proof') context.go('/proof');
              if (key == 'my') context.go('/mypage');
            },
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 92),
          child: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator(color: CMColors.blue))
              : snapshot.hasError
                  ? CMErrorView(message: '홈 정보를 불러오지 못했어요.', onRetry: _refresh)
                  : _HomeContent(
                      data: snapshot.data!,
                      onRefresh: _refresh,
                      nickname: ref.read(authControllerProvider).currentUser?.nickname ?? '회원',
                    ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.data, required this.onRefresh, required this.nickname});

  final _HomeData data;
  final VoidCallback onRefresh;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final rooms = data.rooms;
    final inProgress = rooms.where((e) => e.status == 'IN_PROGRESS').toList();
    final settled = rooms.where((e) => e.status == 'SETTLED').toList();
    final featuredRooms = inProgress.isNotEmpty ? inProgress : rooms;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: CMColors.blue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('내 미션방', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: CMColors.text)),
                    const SizedBox(height: 6),
                    Text('$nickname님, 오늘도 화이팅이에요! 💪', style: const TextStyle(fontSize: 12, color: CMColors.sub)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, size: 29, color: CMColors.text),
                    if (data.unreadCount > 0)
                      Positioned(
                        right: -5,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: CMColors.red, borderRadius: BorderRadius.circular(12)),
                          child: Text('${data.unreadCount}', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SummaryHero(
            inProgress: inProgress.length,
            settled: settled.length,
            unread: data.unreadCount,
          ),
          const SizedBox(height: 18),
          _PointCard(wallet: data.wallet),
          const SizedBox(height: 28),
          Row(
            children: [
              const Text('진행 중인 방', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: CMColors.text)),
              const Spacer(),
              Text('${inProgress.length}개', style: const TextStyle(fontSize: 13, color: CMColors.sub, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          if (featuredRooms.isEmpty)
            CMEmptyState(
              title: '참여 중인 미션방이 없어요',
              message: '친구들과 새 미션방을 만들고 인증을 시작해 보세요.',
              icon: Icons.flag_outlined,
            )
          else
            ...featuredRooms.map((room) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _FeaturedRoomCard(room: room),
                )), 
        ],
      ),
    );
  }
}



class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.inProgress,
    required this.settled,
    required this.unread,
  });

  final int inProgress;
  final int settled;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          BoxShadow(
            color: CMColors.blue.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              SizedBox(width: 7),
              Text('오늘의 요약', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _HeroMetric(icon: Icons.flag_rounded, value: '$inProgress', label: '진행 중인 방')),
              const SizedBox(width: 10),
              Expanded(child: _HeroMetric(icon: Icons.emoji_events_rounded, value: '$settled', label: '정산 완료 방')),
              const SizedBox(width: 10),
              Expanded(child: _HeroMetric(icon: Icons.notifications_rounded, value: '$unread', label: '읽지 않은 알림')),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/rooms'),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    alignment: Alignment.center,
                    child: const Text('내 미션방 확인하기  →', style: TextStyle(color: CMColors.blue, fontSize: 13, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/proof'),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('인증하러 가기', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 5),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 9, fontWeight: FontWeight.w800, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({required this.wallet});
  final PointWalletModel wallet;

  @override
  Widget build(BuildContext context) {
    return CMCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/points'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('보유 포인트', style: TextStyle(fontSize: 12, color: CMColors.sub)),
                  const SizedBox(height: 4),
                  Text(formatPoint(wallet.balance), style: const TextStyle(fontSize: 27, color: CMColors.text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('예치금 / 정산 보상에 사용돼요', style: TextStyle(fontSize: 10, color: CMColors.muted)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/points'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(13)),
              child: const Text('내 포인트 내역 ›', style: TextStyle(color: CMColors.blue, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedRoomCard extends StatelessWidget {
  const _FeaturedRoomCard({required this.room});
  final RoomSummaryModel room;

  @override
  Widget build(BuildContext context) {
    return CMCard(
      padding: const EdgeInsets.all(18),
      child: InkWell(
        onTap: () => context.push('/rooms/${room.id}'),
        child: Column(
          children: [
            Row(
              children: [
                _RoomIcon(room: room),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: CMColors.text)),
                      const SizedBox(height: 5),
                      Text(room.description ?? '친구들과 함께 미션 완주하기', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: CMColors.sub)),
                    ],
                  ),
                ),
                CMPill(label: roomStatusText(room.status), color: statusColor(room.status), background: statusBgColor(room.status)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Meta(icon: Icons.groups_rounded, value: '${room.currentMemberCount}/${room.maxMembers}명'),
                _Meta(icon: Icons.account_balance_wallet_rounded, value: formatPoint(room.stakePoint)),
                _Meta(icon: Icons.timer_rounded, value: proofFrequencyText(room.proofFrequencyType, room.requiredProofCount)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 34,
              decoration: BoxDecoration(color: room.status == 'SETTLED' ? CMColors.gray : CMColors.greenBg, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                room.status == 'SETTLED' ? '🏆 정산 결과 확인 가능' : '✓ 오늘 인증 가능',
                style: TextStyle(
                  color: room.status == 'SETTLED' ? CMColors.sub : CMColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomIcon extends StatelessWidget {
  const _RoomIcon({required this.room});
  final RoomSummaryModel room;

  @override
  Widget build(BuildContext context) {
    final isSettled = room.status == 'SETTLED';
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isSettled ? CMColors.purple : CMColors.green,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(isSettled ? Icons.directions_run_rounded : Icons.fitness_center_rounded, color: Colors.white, size: 27),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 15, color: CMColors.muted),
          const SizedBox(width: 4),
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: CMColors.sub, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.rooms,
    required this.wallet,
    required this.unreadCount,
  });

  final List<RoomSummaryModel> rooms;
  final PointWalletModel wallet;
  final int unreadCount;
}
