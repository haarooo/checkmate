import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../models/room_model.dart';
import '../models/settlement_model.dart';
import '../ui/checkmate_ui.dart';

class SettlementResultScreen extends ConsumerStatefulWidget {
  const SettlementResultScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<SettlementResultScreen> createState() => _SettlementResultScreenState();
}

class _SettlementResultScreenState extends ConsumerState<SettlementResultScreen> {
  late Future<_SettlementData> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_SettlementData> _load() async {
    final service = ref.read(roomServiceProvider);
    final room = await service.getRoomDetail(widget.roomId);
    final settlement = await service.getSettlement(widget.roomId);
    return _SettlementData(room: room, settlement: settlement);
  }

  void _refresh() {
    setState(() => future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      child: FutureBuilder<_SettlementData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CMColors.blue));
          }
          if (snapshot.hasError) {
            return CMErrorView(message: '정산 결과를 불러오지 못했어요.', onRetry: _refresh);
          }

          final data = snapshot.data!;
          final settlement = data.settlement;
          final allSuccess = settlement.failedCount == 0;
          final allFailed = settlement.successCount == 0;
          final badge = allSuccess ? '전원 성공' : allFailed ? '전원 실패' : '일부 성공';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              CMTopBar(
                title: '정산 결과',
                badge: badge,
                onBack: () => context.canPop() ? context.pop() : context.go('/rooms/${widget.roomId}'),
              ),
              const SizedBox(height: 22),
              if (allSuccess)
                _AllSuccess(data: data)
              else if (allFailed)
                _AllFailed(data: data)
              else
                _PartialSuccess(data: data),
            ],
          );
        },
      ),
    );
  }
}

class _AllSuccess extends StatelessWidget {
  const _AllSuccess({required this.data});
  final _SettlementData data;

  @override
  Widget build(BuildContext context) {
    final s = data.settlement;
    return Column(
      children: [
        CMGradientCard(
          colors: const [Color(0xFF0EA5E9), Color(0xFF22C55E)],
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD166), size: 44),
              ),
              const SizedBox(height: 15),
              const Text('전원 성공했어요!', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('모든 멤버가 목표를 달성했어요.', style: TextStyle(color: Color(0xFFEFFFF6), fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          items: [
            _SummaryData('총 예치금', formatPoint(s.totalPotPoint), CMColors.text),
            _SummaryData('성공 인원', '${s.successCount}명', CMColors.green),
            _SummaryData('실패 인원', '${s.failedCount}명', CMColors.blue),
          ],
          footer: '성공 기준  ${s.requiredSuccessCount}회 이상 (${data.room.targetRate}%)',
        ),
        const SizedBox(height: 14),
        CMCard(
          background: const Color(0xFFF8FBFF),
          borderColor: const Color(0xFFCFE1FF),
          child: Row(
            children: [
              Expanded(child: _SimpleBox(label: '시스템 보너스', value: '+${formatPoint(s.systemBonusPoint)}', sub: '전원 성공 보너스', color: CMColors.blue)),
              Container(width: 1, height: 50, color: CMColors.line),
              Expanded(child: _SimpleBox(label: '1인당 분배', value: '+${formatPoint(s.successCount == 0 ? 0 : s.systemBonusPoint ~/ s.successCount)}', sub: '멤버별 균등 분배', color: CMColors.blue)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('멤버별 결과'),
        const SizedBox(height: 10),
        ...s.members.map((m) => _MemberResult(member: m, allFailed: false)),
        const SizedBox(height: 16),
        CMPrimaryButton(label: '홈으로 가기', onPressed: () => context.go('/home')),
      ],
    );
  }
}

class _PartialSuccess extends StatelessWidget {
  const _PartialSuccess({required this.data});
  final _SettlementData data;

  @override
  Widget build(BuildContext context) {
    final s = data.settlement;
    final successMembers = s.members.where((m) => m.resultStatus == 'SUCCESS').toList();
    final failedStake = s.failedCount * data.room.stakePoint;
    final perSuccess = successMembers.isEmpty ? 0 : failedStake ~/ successMembers.length;

    return Column(
      children: [
        CMGradientCard(
          padding: const EdgeInsets.fromLTRB(22, 23, 22, 23),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('성공한 멤버가\n보상을 받았어요!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
                    SizedBox(height: 10),
                    Text('실패자의 예치금이 성공자에게 분배됩니다.', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 36),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          items: [
            _SummaryData('총 예치금', formatPoint(s.totalPotPoint), CMColors.text),
            _SummaryData('성공 인원', '${s.successCount}명', CMColors.green),
            _SummaryData('실패 인원', '${s.failedCount}명', CMColors.red),
          ],
          footer: '성공 기준  ${s.requiredSuccessCount}회 이상 (${data.room.targetRate}%)',
        ),
        const SizedBox(height: 14),
        CMCard(
          child: Row(
            children: [
              Expanded(
                child: _FlowBox(
                  label: '실패자 예치금',
                  value: formatPoint(failedStake),
                  sub: '${s.failedCount}명 × ${formatPoint(data.room.stakePoint)}',
                  color: CMColors.red,
                  bg: CMColors.redBg,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, color: CMColors.sub, size: 22),
              ),
              Expanded(
                child: _FlowBox(
                  label: '성공자 분배',
                  value: '+${formatPoint(failedStake)}',
                  sub: '1인당 +${formatPoint(perSuccess)}',
                  color: CMColors.green,
                  bg: CMColors.greenBg,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('멤버별 결과'),
        const SizedBox(height: 10),
        ...s.members.map((m) => _MemberResult(member: m, allFailed: false)),
        const SizedBox(height: 16),
        CMPrimaryButton(label: '홈으로 가기', onPressed: () => context.go('/home')),
      ],
    );
  }
}

class _AllFailed extends StatelessWidget {
  const _AllFailed({required this.data});
  final _SettlementData data;

  @override
  Widget build(BuildContext context) {
    final s = data.settlement;
    final refundPool = s.totalPotPoint - s.systemFeePoint;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF414553),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 12)),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('목표를 달성하지 못했어요', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  SizedBox(height: 9),
                  Text('다음 미션에서 다시 도전해요.', style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: const Icon(Icons.thunderstorm_rounded, color: Colors.white, size: 36),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          items: [
            _SummaryData('총 예치금', formatPoint(s.totalPotPoint), CMColors.text),
            _SummaryData('시스템 패널티', '-${formatPoint(s.systemFeePoint)}', CMColors.red),
            _SummaryData('환불 풀', formatPoint(refundPool), CMColors.text),
          ],
          footer: '전원 실패 시 예치금의 30%가 패널티 처리됩니다.',
        ),
        const SizedBox(height: 14),
        CMCard(
          background: CMColors.redBg,
          borderColor: const Color(0xFFFECACA),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.warning_amber_rounded, color: CMColors.red, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '환불 안내\n시스템 패널티를 제외한 금액이 멤버에게 환불됩니다.',
                  style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 11, height: 1.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('멤버별 결과'),
        const SizedBox(height: 10),
        ...s.members.map((m) => _MemberResult(member: m, allFailed: true)),
        const SizedBox(height: 16),
        CMPrimaryButton(label: '홈으로 가기', onPressed: () => context.go('/home')),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items, required this.footer});
  final List<_SummaryData> items;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return CMCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        children: [
          Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: Column(
                      children: [
                        Text(item.label, style: const TextStyle(color: CMColors.sub, fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 7),
                        FittedBox(
                          child: Text(item.value, style: TextStyle(color: item.color, fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 13),
          Container(height: 1, color: CMColors.line),
          const SizedBox(height: 13),
          Text(footer, textAlign: TextAlign.center, style: const TextStyle(color: CMColors.text, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _FlowBox extends StatelessWidget {
  const _FlowBox({required this.label, required this.value, required this.sub, required this.color, required this.bg});
  final String label;
  final String value;
  final String sub;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          FittedBox(child: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900))),
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SimpleBox extends StatelessWidget {
  const _SimpleBox({required this.label, required this.value, required this.sub, required this.color});
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        FittedBox(child: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900))),
        const SizedBox(height: 4),
        Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: CMColors.sub, fontSize: 10)),
      ],
    );
  }
}

class _MemberResult extends StatelessWidget {
  const _MemberResult({required this.member, required this.allFailed});
  final SettlementMemberModel member;
  final bool allFailed;

  @override
  Widget build(BuildContext context) {
    final success = member.resultStatus == 'SUCCESS';
    final color = success ? CMColors.green : CMColors.red;
    final bg = success ? CMColors.greenBg : CMColors.redBg;
    final amountPrefix = (!allFailed && success) ? '+' : '';
    final amountLabel = allFailed ? '환불' : success ? '정산 보상' : '보상 없음';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          CMAvatar(label: member.nickname, color: color, size: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(member.nickname, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CMColors.text, fontSize: 13, fontWeight: FontWeight.w900))),
                const SizedBox(width: 6),
                CMPill(label: success ? '성공' : '실패', color: color, background: Colors.white.withValues(alpha: 0.78), fontSize: 8, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3)),
              ]),
              const SizedBox(height: 6),
              Text(
                '확인 ${member.confirmedCount}/${member.requiredSuccessCount}회 · ${member.proofRate.round()}%',
                style: const TextStyle(color: CMColors.sub, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            FittedBox(
              child: Text(
                '$amountPrefix${formatPoint(member.rewardPoint)}',
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 3),
            Text(amountLabel, style: const TextStyle(color: CMColors.sub, fontSize: 9, fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: CMColors.text)),
    );
  }
}

class _SettlementData {
  const _SettlementData({required this.room, required this.settlement});
  final RoomDetailModel room;
  final SettlementModel settlement;
}
