
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_colors.dart';
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
  int _unreadCount = 0;

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

    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await ref.read(notificationServiceProvider).getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  void _onTodayMissionTap() {
    final inProgressRooms = rooms.where((r) => r.status == 'IN_PROGRESS').toList();
    if (inProgressRooms.isNotEmpty) {
      context.go('/rooms/${inProgressRooms.first.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('진행중인 미션방이 없어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // ─── 헤더 ──────────────────────────────────────────────
              Container(
                color: AppColors.surface,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 20, 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('내 미션방', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              SizedBox(height: 2),
                              Text('친구들과 함께 인증하고, 함께 성공해요', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        _bellIcon(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: AppColors.borderLight),
              // ─── 본문 ────────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: loadHome,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _todayCheckHeroCard(),
                        const SizedBox(height: 12),
                        _pointSubCard(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('참여 중인 방', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('${isLoading ? '-' : rooms.length}개', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          )
                        else if (errorMessage != null)
                          _messageBox(errorMessage!, isError: true)
                        else if (rooms.isEmpty)
                          _emptyRoomBox()
                        else
                          ...rooms.map((room) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildRoomCard(
                              room: room,
                              onTap: () => context.go('/rooms/${room.id}'),
                            ),
                          )),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => context.go('/rooms/create'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('새 인증방 만들기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
          // ─── 하단 네비게이션 ─────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.home_rounded, '홈', true),
                      _buildNavItem(Icons.fact_check_outlined, '인증', false, onTap: () {
                        if (rooms.isNotEmpty) context.go('/rooms/${rooms.first.id}/proofs');
                      }),
                      _buildNavItem(Icons.group_outlined, '방', false, onTap: () => context.go('/rooms/join')),
                      _buildNavItem(Icons.person_outline, '마이', false, onTap: () => context.go('/mypage')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 오늘의 체크 Hero 카드 ────────────────────────────────────────

  Widget _todayCheckHeroCard() {
    final inProgressCount = rooms.where((r) => r.status == 'IN_PROGRESS').length;
    final settledCount = rooms.where((r) => r.status == 'SETTLED').length;
    final hasNotification = _unreadCount > 0;

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
            Positioned(
              right: -30, top: -30,
              child: Container(width: 140, height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07))),
            ),
            Positioned(
              left: -20, bottom: -20,
              child: Container(width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 오늘의 체크 pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('오늘의 체크', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('내 미션 요약', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  // 미션 요약 메트릭
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('불러오는 중...', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                    )
                  else
                    Row(
                      children: [
                        _heroMetricTile('$inProgressCount개', '진행중 방', Icons.flag_rounded),
                        const SizedBox(width: 28),
                        _heroMetricTile('$settledCount개', '정산완료 방', Icons.emoji_events_rounded),
                        const SizedBox(width: 28),
                        _heroMetricTile(
                          hasNotification ? '$_unreadCount개' : '없음',
                          hasNotification ? '확인할 알림' : '알림 없음',
                          hasNotification ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  // CTA 버튼
                  GestureDetector(
                    onTap: _onTodayMissionTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('오늘 미션 확인하기', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMetricTile(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── 포인트 서브 카드 ─────────────────────────────────────────────

  Widget _pointSubCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('보유 포인트', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  wallet == null ? '-' : UiMappers.point(wallet!.balance),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                const Text('예치금 / 정산 보상에 사용돼요', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/mypage'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('내 포인트 내역', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 11),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 방 카드 ─────────────────────────────────────────────────

  Widget _buildRoomCard({required RoomSummaryModel room, VoidCallback? onTap}) {
    final statusColor = UiMappers.statusColor(room.status);
    final statusLabel = UiMappers.statusLabel(room.status);
    final softBg = statusColor.withValues(alpha: 0.08);
    final hint = _statusHint(room.status);
    final hintIcon = _statusHintIcon(room.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(18),
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
                      Text(room.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(
                        UiMappers.roomDescriptionFallback(room.title, room.description),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: softBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(Icons.people_outline, '${room.currentMemberCount}/${room.maxMembers}명'),
                const SizedBox(width: 12),
                _infoChip(Icons.account_balance_wallet_outlined, UiMappers.stakePointLabel(room.stakePoint)),
                const SizedBox(width: 12),
                _infoChip(Icons.track_changes, UiMappers.frequencyGoalLabel(room.proofFrequencyType, room.requiredProofCount)),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(hintIcon, size: 13, color: statusColor),
                    const SizedBox(width: 6),
                    Text(hint, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _statusHint(String status) {
    switch (status) {
      case 'IN_PROGRESS': return '오늘 인증 가능';
      case 'SETTLED': return '정산 결과 확인 가능';
      case 'READY': return '시작 대기중';
      case 'RECRUITING': return '모집중';
      default: return null;
    }
  }

  IconData _statusHintIcon(String status) {
    switch (status) {
      case 'IN_PROGRESS': return Icons.check_circle_outline;
      case 'SETTLED': return Icons.emoji_events_outlined;
      case 'READY': return Icons.hourglass_empty;
      case 'RECRUITING': return Icons.group_add_outlined;
      default: return Icons.info_outline;
    }
  }

  // ─── 빈 상태 ─────────────────────────────────────────────────

  Widget _emptyRoomBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.flag_outlined, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          const Text('아직 참여 중인 방이 없어요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('새 인증방을 만들어서 시작해 보세요!', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
        color: isError ? AppColors.errorSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isError ? const Color(0xFFFECACA) : AppColors.borderLight),
      ),
      child: Text(message, style: TextStyle(color: isError ? AppColors.error : AppColors.textSecondary)),
    );
  }

  // ─── 알림 벨 ─────────────────────────────────────────────────

  Widget _bellIcon() {
    final label = _unreadCount > 99 ? '99+' : '$_unreadCount';
    return GestureDetector(
      onTap: () => context.push('/notifications').then((_) => _refreshUnreadCount()),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.notifications_none_outlined, size: 26, color: AppColors.textSecondary),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -2, top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Info Chip ────────────────────────────────────────────────

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  // ─── 네비게이션 아이템 ─────────────────────────────────────────

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: isActive ? AppColors.primary : AppColors.textMuted),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppColors.primary : AppColors.textMuted)),
        ],
      ),
    );
  }
}
