
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
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
    final balance = wallet?.balance ?? 100000;
    final formatter = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home'))]),
              const Text('마이페이지', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadMyPage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  _profileCard(currentUser),
                  const SizedBox(height: 16),
                  _pointCard(balance),
                  const SizedBox(height: 16),
                  _ledgerCard(formatter),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('로그아웃', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  Widget _profileCard(UserModel? currentUser) {
    final name = currentUser?.name ?? '김철수';
    final nickname = currentUser?.nickname ?? 'owner_124909';
    final role = currentUser?.role ?? 'ROLE_USER';
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          Container(width: 64, height: 64, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]), shape: BoxShape.circle), child: Center(child: Text(UiMappers.initialFromName(name), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(nickname, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)))])),
          TextButton(onPressed: () {}, child: const Text('편집', style: TextStyle(fontSize: 14, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _miniInfo('권한', role.replaceAll('ROLE_', ''))), const SizedBox(width: 12), Expanded(child: _miniInfo('가입 보너스', '100,000P'))]),
      ]),
    );
  }

  Widget _pointCard(int balance) {
    return Container(
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.monetization_on_outlined, color: Colors.white)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('보유 포인트', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)), const SizedBox(height: 4), Text(UiMappers.point(balance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))])),
      ]),
    );
  }

  Widget _ledgerCard(NumberFormat formatter) {
    final displayLedgers = ledgers.isEmpty ? null : ledgers.take(5).toList();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('포인트 이력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF3B82F6))))
        else if (displayLedgers == null)
          Column(children: [_staticLedger('방 참여 예치금', '-15,000P', '식단 관리 1달 챌린지', '2024.05.05 18:45', false), const SizedBox(height: 12), _staticLedger('가입 보너스', '+100,000P', '회원가입 축하 포인트', '2024.05.01 12:00', true)])
        else
          ...displayLedgers.map((ledger) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ledgerItem(ledger, formatter))),
      ]),
    );
  }

  Widget _ledgerItem(PointLedgerModel ledger, NumberFormat formatter) {
    final isPlus = ledger.amount >= 0;
    final title = _ledgerTitle(ledger.type);
    return _staticLedger(title, '${isPlus ? '+' : ''}${formatter.format(ledger.amount)}P', ledger.description, _formatDate(ledger.createdAt), isPlus);
  }

  String _ledgerTitle(String type) {
    switch (type) {
      case 'SIGNUP_BONUS': return '가입 보너스';
      case 'TEST_CHARGE': return '테스트 충전';
      case 'ROOM_STAKE': return '방 참여 예치금';
      case 'ROOM_SETTLEMENT_REWARD': return '정산 보상';
      case 'ROOM_REFUND': return '예치금 환불';
      default: return type;
    }
  }

  String _formatDate(DateTime date) => '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Widget _staticLedger(String title, String amount, String description, String date, bool isPlus) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: isPlus ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)), child: Icon(isPlus ? Icons.card_giftcard : Icons.trending_down, color: isPlus ? const Color(0xFFEAB308) : const Color(0xFFEF4444))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))), const SizedBox(height: 2), Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))])),
      Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: isPlus ? const Color(0xFFEAB308) : const Color(0xFFEF4444))),
    ]));
  }

  Widget _miniInfo(String label, String value) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))]));
}
