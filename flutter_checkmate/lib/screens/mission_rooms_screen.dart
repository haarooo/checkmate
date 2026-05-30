import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../models/room_model.dart';
import '../ui/checkmate_ui.dart';

class MissionRoomsScreen extends ConsumerStatefulWidget {
  const MissionRoomsScreen({super.key});

  @override
  ConsumerState<MissionRoomsScreen> createState() => _MissionRoomsScreenState();
}

class _MissionRoomsScreenState extends ConsumerState<MissionRoomsScreen> {
  late Future<List<RoomSummaryModel>> future;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    future = ref.read(roomServiceProvider).getMyRooms();
  }

  void _refresh() {
    setState(() => future = ref.read(roomServiceProvider).getMyRooms());
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      bottom: CMBottomNav(
        current: 'rooms',
        onTap: (key) {
          if (key == 'home') context.go('/home');
          if (key == 'rooms') context.go('/rooms');
          if (key == 'proof') context.go('/proof');
              if (key == 'my') context.go('/mypage');
        },
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 92),
      child: FutureBuilder<List<RoomSummaryModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CMColors.blue));
          }
          if (snapshot.hasError) {
            return CMErrorView(message: '미션방 목록을 불러오지 못했어요.', onRetry: _refresh);
          }
          final rooms = snapshot.data ?? [];
          final visible = rooms.where((r) => tab == 0 ? r.status != 'SETTLED' : r.status == 'SETTLED').toList();

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: CMColors.blue,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Text('미션방', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: CMColors.text)),
                const SizedBox(height: 18),
                _Tabs(
                  current: tab,
                  onChanged: (v) => setState(() => tab = v),
                ),
                const SizedBox(height: 22),
                if (visible.isEmpty)
                  CMEmptyState(
                    title: tab == 0 ? '참여 중인 방이 없어요' : '정산 완료 방이 없어요',
                    message: '친구들과 미션방을 만들고 인증을 시작해 보세요.',
                    icon: Icons.flag_outlined,
                  )
                else
                  ...visible.map((room) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RoomListCard(room: room),
                      )),
                const SizedBox(height: 8),
                CMPrimaryButton(
                  label: '새 미션방 만들기',
                  icon: Icons.add_rounded,
                  onPressed: () => context.push('/rooms/create'),
                ),
                const SizedBox(height: 10),
                CMOutlineButton(
                  label: '초대 링크로 참여하기',
                  icon: Icons.link_rounded,
                  onPressed: () => context.push('/rooms/join'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.current, required this.onChanged});
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _TabButton(label: '참여 중인 방', selected: current == 0, onTap: () => onChanged(0)),
          _TabButton(label: '정산 완료 방', selected: current == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? CMColors.blue : Colors.transparent, borderRadius: BorderRadius.circular(17)),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : CMColors.sub,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomListCard extends StatelessWidget {
  const _RoomListCard({required this.room});
  final RoomSummaryModel room;

  @override
  Widget build(BuildContext context) {
    final settled = room.status == 'SETTLED';
    final iconColor = settled ? CMColors.purple : CMColors.green;
    final icon = settled ? Icons.emoji_events_rounded : Icons.flag_rounded;

    return CMCard(
      padding: const EdgeInsets.all(18),
      child: InkWell(
        onTap: () => context.push('/rooms/${room.id}'),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(17)),
                  child: Icon(icon, color: Colors.white, size: 27),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: CMColors.text)),
                      const SizedBox(height: 4),
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
              decoration: BoxDecoration(color: settled ? CMColors.gray : CMColors.greenBg, borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(settled ? Icons.emoji_events_rounded : Icons.check_circle_rounded, color: settled ? CMColors.sub : CMColors.green, size: 16),
                  const SizedBox(width: 7),
                  Text(
                    settled ? '정산 결과 확인 가능' : '오늘 인증 가능',
                    style: TextStyle(color: settled ? CMColors.sub : CMColors.green, fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: CMColors.muted, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
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
