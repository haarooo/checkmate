import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../models/point_model.dart';
import '../ui/checkmate_ui.dart';

class PointHistoryScreen extends ConsumerStatefulWidget {
  const PointHistoryScreen({super.key});

  @override
  ConsumerState<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends ConsumerState<PointHistoryScreen> {
  late Future<_PointHistoryData> future;
  int filter = 0;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_PointHistoryData> _load() async {
    final pointService = ref.read(pointServiceProvider);
    final wallet = await pointService.getMyWallet();
    final ledgers = await pointService.getMyLedgers();
    return _PointHistoryData(wallet: wallet, ledgers: ledgers);
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
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 92),
      child: FutureBuilder<_PointHistoryData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CMColors.blue));
          }
          if (snapshot.hasError) {
            return CMErrorView(message: '포인트 내역을 불러오지 못했어요.', onRetry: _refresh);
          }

          final data = snapshot.data!;
          final visible = _filter(data.ledgers);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: CMColors.blue,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                CMTopBar(
                  title: '포인트 내역',
                  onBack: () => context.canPop() ? context.pop() : context.go('/mypage'),
                  actions: const [
                    Icon(Icons.filter_list_rounded, color: CMColors.text),
                  ],
                ),
                const SizedBox(height: 22),
                CMGradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('총 보유 포인트', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(formatPoint(data.wallet.balance), style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 18),
                      const Divider(color: Color(0x55FFFFFF)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _Summary(label: '총 획득', value: '+${formatPoint(_sumPositive(data.ledgers))}')),
                          Expanded(child: _Summary(label: '총 사용', value: formatPoint(_sumNegative(data.ledgers)))),
                          Expanded(child: _Summary(label: '정산 예치금', value: formatPoint(_sumStake(data.ledgers).abs()))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _FilterChips(current: filter, onChanged: (v) => setState(() => filter = v)),
                const SizedBox(height: 22),
                if (visible.isEmpty)
                  const CMEmptyState(title: '포인트 이력이 없어요', message: '조건에 맞는 포인트 이력이 없습니다.', icon: Icons.receipt_long_outlined)
                else
                  CMCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: visible.map((ledger) => _LedgerTile(ledger: ledger)).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PointLedgerModel> _filter(List<PointLedgerModel> items) {
    if (filter == 1) return items.where((e) => _title(e).contains('반환')).toList();
    if (filter == 2) return items.where((e) => _title(e).contains('보상')).toList();
    if (filter == 3) return items.where((e) => _title(e).contains('예치금') && e.amount < 0).toList();
    return items;
  }

  int _sumPositive(List<PointLedgerModel> items) => items.where((e) => e.amount > 0).fold(0, (sum, e) => sum + e.amount);
  int _sumNegative(List<PointLedgerModel> items) => items.where((e) => e.amount < 0).fold(0, (sum, e) => sum + e.amount);
  int _sumStake(List<PointLedgerModel> items) => items.where((e) => _title(e).contains('예치금')).fold(0, (sum, e) => sum + e.amount);

  String _title(PointLedgerModel ledger) => ledgerTitle(ledger);
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFDBEAFE), fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onChanged});
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = ['전체', '예치금 반환', '정산 보상', '방 예치금'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = current == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : CMColors.gray,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: selected ? CMColors.blue : CMColors.line),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(color: selected ? CMColors.blue : CMColors.sub, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.ledger});
  final PointLedgerModel ledger;

  @override
  Widget build(BuildContext context) {
    final positive = ledger.amount >= 0;
    final title = ledgerTitle(ledger);
    final color = positive ? CMColors.green : CMColors.red;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CMColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: positive ? CMColors.greenBg : CMColors.redBg, shape: BoxShape.circle),
            child: Icon(positive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, color: CMColors.text, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(ledger.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: CMColors.sub)),
              const SizedBox(height: 4),
              Text(formatDateTime(ledger.createdAt), style: const TextStyle(fontSize: 10, color: CMColors.muted)),
            ]),
          ),
          Text('${positive ? '+' : ''}${formatPoint(ledger.amount)}', style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

String ledgerTitle(PointLedgerModel ledger) {
  final type = ledger.type.toUpperCase();
  final desc = ledger.description;
  if (type.contains('STAKE') || (ledger.amount < 0 && desc.contains('예치'))) return '방 예치금';
  if (type.contains('REWARD') || desc.contains('보상')) return '정산 보상';
  if (type.contains('REFUND') || desc.contains('반환')) return '정산 예치금 반환';
  if (ledger.amount < 0) return '포인트 사용';
  return '포인트 적립';
}

class _PointHistoryData {
  const _PointHistoryData({required this.wallet, required this.ledgers});
  final PointWalletModel wallet;
  final List<PointLedgerModel> ledgers;
}
