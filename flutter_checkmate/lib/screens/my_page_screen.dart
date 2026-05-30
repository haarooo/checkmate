
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/ui_mappers.dart';
import '../models/point_model.dart';
import '../models/user_model.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool isLoading = true;
  String? errorMessage;
  UserModel? user;
  PointWalletModel? wallet;
  List<PointLedgerModel> ledgers = [];

  @override
  void initState() {
    super.initState();
    loadMyPage();
  }

  Future<void> loadMyPage() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final authService = ref.read(authServiceProvider);
      final pointService = ref.read(pointServiceProvider);
      final userResult = await authService.getMe();
      final walletResult = await pointService.getMyWallet();
      final ledgerResult = await pointService.getMyLedgers();
      if (!mounted) return;
      setState(() {
        user = userResult;
        wallet = walletResult;
        ledgers = ledgerResult;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    await ref.read(authControllerProvider).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    final formatter = NumberFormat('#,###');

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
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text('마이페이지', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.borderLight),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadMyPage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(children: [
                  _profileCard(currentUser),
                  const SizedBox(height: 14),
                  _pointCard(),
                  const SizedBox(height: 14),
                  _ledgerCard(formatter),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
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
                        Expanded(child: Text(errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('로그아웃', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 프로필 카드 ──────────────────────────────────────────────

  Widget _profileCard(UserModel? currentUser) {
    final name = currentUser?.name ?? '-';
    final nickname = currentUser?.nickname ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(UiMappers.initialFromName(name), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(nickname, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                child: const Text('Checkmate 멤버', style: TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ─── 포인트 카드 ──────────────────────────────────────────────

  Widget _pointCard() {
    final balance = wallet?.balance;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: const Icon(Icons.monetization_on_outlined, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('보유 포인트', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              balance == null ? '-' : UiMappers.point(balance),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─── 포인트 이력 카드 ─────────────────────────────────────────

  Widget _ledgerCard(NumberFormat formatter) {
    final displayLedgers = ledgers.isEmpty ? null : ledgers.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('포인트 이력', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
        else if (displayLedgers == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('포인트 이력이 없어요', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
          )
        else
          ...displayLedgers.map((ledger) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _ledgerItem(ledger, formatter))),
      ]),
    );
  }

  Widget _ledgerItem(PointLedgerModel ledger, NumberFormat formatter) {
    final isPlus = ledger.amount >= 0;
    final title = _ledgerTitle(ledger.type);
    final amountText = '${isPlus ? '+' : ''}${formatter.format(ledger.amount)}P';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isPlus ? AppColors.successSoft : AppColors.errorSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPlus ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isPlus ? AppColors.successDark : AppColors.error,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(ledger.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(_formatDate(ledger.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        Text(amountText, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isPlus ? AppColors.successDark : AppColors.error)),
      ]),
    );
  }

  String _ledgerTitle(String type) {
    switch (type) {
      case 'SIGNUP_BONUS': return '가입 보너스';
      case 'TEST_CHARGE': return '테스트 충전';
      case 'ROOM_STAKE': return '방 예치금';
      case 'ROOM_SETTLEMENT_REFUND': return '정산 예치금 반환';
      case 'ROOM_SETTLEMENT_REWARD': return '정산 보상';
      case 'ROOM_SETTLEMENT_SUCCESS_BONUS': return '전원 성공 보너스';
      case 'ROOM_REFUND': return '예치금 환불';
      default: return type;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
