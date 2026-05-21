
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/ui_mappers.dart';
import '../models/point_model.dart';
import '../models/room_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isLoading = true;
  String? errorMessage;
  PointWalletModel? wallet;
  List<RoomSummaryModel> rooms = [];

  @override
  void initState() {
    super.initState();
    loadHome();
  }

  Future<void> loadHome() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final pointService = ref.read(pointServiceProvider);
      final roomService = ref.read(roomServiceProvider);
      final results = await Future.wait([
        pointService.getMyWallet(),
        roomService.getMyRooms(),
      ]);
      if (!mounted) return;
      setState(() {
        wallet = results[0] as PointWalletModel;
        rooms = results[1] as List<RoomSummaryModel>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: const Row(
                  children: [
                    Text('내 미션방', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFF3F4F6)),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: loadHome,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pointCard(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('참여 중인 방', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                            Text('${rooms.length}개', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isLoading)
                          ...List.generate(3, (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildRoomCard(
                                  title: index == 0 ? '여름 전까지 4주 운동방' : index == 1 ? '아침 러닝 챌린지' : '식단 관리 1달 챌린지',
                                  description: index == 0 ? '친구들과 함께 운동 습관 만들기' : index == 1 ? '매일 아침 5km 달리기' : '건강한 식습관 만들기',
                                  status: index == 0 ? '진행중' : index == 1 ? '대기중' : '모집중',
                                  statusColor: index == 0 ? const Color(0xFF22C55E) : index == 1 ? const Color(0xFF3B82F6) : const Color(0xFFF97316),
                                  members: index == 0 ? '3/5명' : index == 1 ? '4/4명' : '2/6명',
                                  points: index == 0 ? '10,000P' : index == 1 ? '20,000P' : '15,000P',
                                  type: index == 1 ? 'WEEKLY' : 'DAILY',
                                  goal: index == 1 ? '주 5회' : index == 0 ? '하루 2회' : '하루 3회',
                                  progress: index == 0 ? 0.5 : null,
                                ),
                              )),
                        if (!isLoading && errorMessage != null)
                          _messageBox(errorMessage!, isError: true),
                        if (!isLoading && errorMessage == null && rooms.isEmpty)
                          _messageBox('아직 참여 중인 방이 없습니다. 새 인증방을 만들어보세요.'),
                        if (!isLoading && errorMessage == null)
                          ...rooms.map((room) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildRoomCard(
                                  title: room.title,
                                  description: UiMappers.roomDescriptionFallback(room.title, room.description),
                                  status: UiMappers.statusLabel(room.status),
                                  statusColor: UiMappers.statusColor(room.status),
                                  members: '${room.currentMemberCount}/${room.maxMembers}명',
                                  points: UiMappers.point(room.stakePoint),
                                  type: room.proofFrequencyType,
                                  goal: UiMappers.frequencyGoal(room.proofFrequencyType, room.requiredProofCount),
                                  progress: room.status == 'IN_PROGRESS' ? 0.5 : null,
                                  onTap: () => context.go('/rooms/${room.id}'),
                                ),
                              )),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('/rooms/create'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('새 인증방 만들기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, '홈', true),
                  _buildNavItem(Icons.fact_check_outlined, '인증', false, onTap: () {
                    if (rooms.isNotEmpty) context.go('/rooms/${rooms.first.id}/proofs');
                  }),
                  _buildNavItem(Icons.group_outlined, '방', false, onTap: () => context.go('/rooms/join')),
                  _buildNavItem(Icons.person_outline, '마이', false, onTap: () => context.go('/mypage')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('보유 포인트', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            wallet == null ? '100,000P' : UiMappers.point(wallet!.balance),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _messageBox(String message, {bool isError = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isError ? const Color(0xFFFECACA) : const Color(0xFFF3F4F6)),
      ),
      child: Text(message, style: TextStyle(color: isError ? const Color(0xFFEF4444) : const Color(0xFF6B7280))),
    );
  }

  Widget _buildRoomCard({
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required String members,
    required String points,
    required String type,
    required String goal,
    double? progress,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: _buildInfoItem(Icons.people_outline, members)), Expanded(child: _buildInfoItem(Icons.attach_money, points))]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _buildInfoItem(Icons.calendar_today_outlined, type)), Expanded(child: _buildInfoItem(Icons.track_changes, goal))]),
            if (progress != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(4))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('1/2', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 16, color: const Color(0xFF9CA3AF)), const SizedBox(width: 8), Flexible(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))))]);
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
