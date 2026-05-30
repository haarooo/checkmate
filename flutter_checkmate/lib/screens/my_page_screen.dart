import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
import '../models/point_model.dart';
import '../models/user_model.dart';
import '../ui/checkmate_ui.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  late Future<_MyPageData> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_MyPageData> _load() async {
    final wallet = await ref.read(pointServiceProvider).getMyWallet();
    final ledgers = await ref.read(pointServiceProvider).getMyLedgers();
    final user = ref.read(authControllerProvider).currentUser;
    return _MyPageData(wallet: wallet, ledgers: ledgers, user: user);
  }

  void _refresh() {
    setState(() => future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      bottom: CMBottomNav(
        current: 'my',
        onTap: (key) {
          if (key == 'home') context.go('/home');
          if (key == 'rooms') context.go('/rooms');
          if (key == 'proof') context.go('/proof');
          if (key == 'my') context.go('/mypage');
        },
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 92),
      child: FutureBuilder<_MyPageData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CMColors.blue));
          }
          if (snapshot.hasError) {
            return CMErrorView(message: '마이페이지 정보를 불러오지 못했어요.', onRetry: _refresh);
          }
          return _MyPageContent(
            data: snapshot.data!,
            onRefresh: _refresh,
            onLogout: () async {
              await ref.read(authControllerProvider).logout();
              if (context.mounted) context.go('/login');
            },
          );
        },
      ),
    );
  }
}

class _MyPageContent extends StatelessWidget {
  const _MyPageContent({required this.data, required this.onRefresh, required this.onLogout});
  final _MyPageData data;
  final VoidCallback onRefresh;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final nickname = data.user?.nickname ?? '멤버';
    final recent = data.ledgers.take(3).toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: CMColors.blue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              const Text('마이페이지', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: CMColors.text)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/notifications'),
                child: const Icon(Icons.notifications_none_rounded, color: CMColors.text, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 22),
          CMCard(
            background: const Color(0xFFF3F7FF),
            child: Row(
              children: [
                CMAvatar(label: nickname, color: CMColors.blue, size: 62),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(nickname, style: const TextStyle(fontSize: 18, color: CMColors.text, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        const CMPill(label: '멤버', color: CMColors.sub, background: Color(0xFFE5EAF2)),
                      ]),
                      const SizedBox(height: 8),
                      const Text('체크메이트와 함께\n꾸준한 인증 습관을 만들어가요! 💪', style: TextStyle(fontSize: 12, color: CMColors.sub, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CMGradientCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('보유 포인트', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(formatPoint(data.wallet.balance), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => context.go('/points'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withValues(alpha: 0.45))),
                        child: const Text('포인트 내역 보기  ›', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ]),
                ),
                Icon(Icons.monetization_on_rounded, color: Colors.white.withValues(alpha: 0.45), size: 80),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Text('최근 포인트 내역', style: TextStyle(fontSize: 16, color: CMColors.text, fontWeight: FontWeight.w900)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/points'),
                child: const Text('전체 보기 ›', style: TextStyle(fontSize: 12, color: CMColors.blue, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CMCard(
            padding: EdgeInsets.zero,
            child: recent.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('아직 포인트 이력이 없어요.', style: TextStyle(color: CMColors.sub)),
                  )
                : Column(
                    children: recent.map((ledger) => _LedgerRow(ledger: ledger)).toList(),
                  ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () { onLogout(); },
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: CMColors.line),
              ),
              child: const Text(
                '로그아웃',
                style: TextStyle(color: CMColors.red, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.ledger});
  final PointLedgerModel ledger;

  @override
  Widget build(BuildContext context) {
    final positive = ledger.amount >= 0;
    final color = positive ? CMColors.green : CMColors.red;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: positive ? CMColors.greenBg : CMColors.redBg, shape: BoxShape.circle),
            child: Icon(positive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_ledgerTitle(ledger), style: const TextStyle(fontSize: 13, color: CMColors.text, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(ledger.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: CMColors.sub)),
              const SizedBox(height: 3),
              Text(formatDateTime(ledger.createdAt), style: const TextStyle(fontSize: 10, color: CMColors.muted)),
            ]),
          ),
          Text(
            '${positive ? '+' : ''}${formatPoint(ledger.amount)}',
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  String _ledgerTitle(PointLedgerModel ledger) {
    final type = ledger.type.toUpperCase();
    if (type.contains('STAKE')) return '방 예치금';
    if (type.contains('REWARD')) return '정산 보상';
    if (type.contains('REFUND')) return '정산 예치금 반환';
    if (ledger.amount < 0) return '방 예치금';
    return '포인트 변동';
  }
}

class _MyPageData {
  const _MyPageData({required this.wallet, required this.ledgers, required this.user});
  final PointWalletModel wallet;
  final List<PointLedgerModel> ledgers;
  final UserModel? user;
}
