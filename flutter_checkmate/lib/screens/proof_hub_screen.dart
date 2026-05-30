import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../models/room_model.dart';
import '../ui/checkmate_ui.dart';

class ProofHubScreen extends ConsumerStatefulWidget {
  const ProofHubScreen({super.key});

  @override
  ConsumerState<ProofHubScreen> createState() => _ProofHubScreenState();
}

class _ProofHubScreenState extends ConsumerState<ProofHubScreen> {
  late Future<List<RoomSummaryModel>> future;

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
        current: 'proof',
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
            return CMErrorView(message: '인증 가능한 방을 불러오지 못했어요.', onRetry: _refresh);
          }

          final rooms = (snapshot.data ?? [])
              .where((room) => room.status == 'IN_PROGRESS')
              .toList();

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: CMColors.blue,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Text('인증', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: CMColors.text)),
                const SizedBox(height: 7),
                const Text('인증을 올리거나 친구 인증을 확인할 방을 선택해요.', style: TextStyle(fontSize: 12, color: CMColors.sub)),
                const SizedBox(height: 24),
                CMGradientCard(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('오늘 인증 플로우', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                            SizedBox(height: 8),
                            Text('방을 선택해서 인증 제출/확인을 진행하세요.', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 34),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('진행 중인 방', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: CMColors.text)),
                    const Spacer(),
                    Text('${rooms.length}개', style: const TextStyle(fontSize: 12, color: CMColors.sub, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 14),
                if (rooms.isEmpty)
                  const CMEmptyState(
                    title: '진행 중인 방이 없어요',
                    message: '인증을 진행할 수 있는 미션방이 아직 없습니다.',
                    icon: Icons.check_circle_outline_rounded,
                  )
                else
                  ...rooms.map((room) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ProofRoomCard(room: room),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProofRoomCard extends StatelessWidget {
  const _ProofRoomCard({required this.room});

  final RoomSummaryModel room;

  @override
  Widget build(BuildContext context) {
    return CMCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: CMColors.green, borderRadius: BorderRadius.circular(17)),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: CMColors.text)),
                  const SizedBox(height: 5),
                  Text(room.description ?? '친구들과 함께 미션 완주하기', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: CMColors.sub)),
                ]),
              ),
              const CMPill(label: '진행중', color: CMColors.green, background: CMColors.greenBg),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ActionButton(label: '인증 올리기', icon: Icons.upload_rounded, filled: true, onTap: () => context.push('/rooms/${room.id}/submit-proof'))),
              const SizedBox(width: 10),
              Expanded(child: _ActionButton(label: '인증 확인', icon: Icons.check_circle_outline_rounded, filled: false, onTap: () => context.push('/rooms/${room.id}/proofs'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.filled, required this.onTap});
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: filled ? CMColors.blue : Colors.white,
          border: Border.all(color: CMColors.blue),
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: filled ? Colors.white : CMColors.blue),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: filled ? Colors.white : CMColors.blue, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
