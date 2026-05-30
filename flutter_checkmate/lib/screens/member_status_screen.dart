import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../ui/checkmate_ui.dart';

class MemberStatusScreen extends ConsumerStatefulWidget {
  const MemberStatusScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<MemberStatusScreen> createState() => _MemberStatusScreenState();
}

class _MemberStatusScreenState extends ConsumerState<MemberStatusScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = ref.read(roomServiceProvider).getMemberStats(widget.roomId);
  }

  void _refresh() {
    setState(() => future = ref.read(roomServiceProvider).getMemberStats(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 102),
      bottom: _BottomActions(roomId: widget.roomId),
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CMColors.blue));
          }
          if (snapshot.hasError) {
            return CMErrorView(message: '멤버 현황을 불러오지 못했어요.', onRetry: _refresh);
          }

          final data = snapshot.data!;
          final title = readString(data['roomTitle'], fallback: '멤버 진행 현황');
          final members = (data['members'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          final success = members.where((m) => readString(m['expectedResult']) == 'SUCCESS').length;
          final waiting = members.where((m) => readString(m['expectedResult']) == 'WAITING_CONFIRM').length;
          final needMore = members.length - success - waiting;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: CMColors.blue,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                CMTopBar(
                  title: '멤버 진행 현황',
                  subtitle: title,
                  onBack: () => context.canPop() ? context.pop() : context.go('/rooms/${widget.roomId}'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _SummaryTile(label: '성공 기준 충족', value: '$success명', percent: members.isEmpty ? 0 : success / members.length, color: CMColors.green, bg: CMColors.greenBg)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryTile(label: '확인 필요', value: '$waiting명', percent: members.isEmpty ? 0 : waiting / members.length, color: CMColors.blue, bg: const Color(0xFFEFF6FF))),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryTile(label: '기준미달', value: '$needMore명', percent: members.isEmpty ? 0 : needMore / members.length, color: CMColors.orange, bg: CMColors.orangeBg)),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: const [
                    Text('멤버 진행 현황', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: CMColors.text)),
                    Spacer(),
                    Text('진행률 순', style: TextStyle(fontSize: 11, color: CMColors.sub, fontWeight: FontWeight.w800)),
                    Icon(Icons.keyboard_arrow_down_rounded, color: CMColors.sub, size: 16),
                  ],
                ),
                const SizedBox(height: 14),
                ...members.map((member) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MemberStatCard(member: member),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(value, style: TextStyle(color: color, fontSize: 23, fontWeight: FontWeight.w900)),
          const Spacer(),
          CMProgressBar(value: percent, color: color, height: 5, background: Colors.white.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}

class _MemberStatCard extends StatelessWidget {
  const _MemberStatCard({required this.member});

  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final name = readString(member['nickname']);
    final role = readString(member['role']);
    final submitted = readInt(member['submittedCount']);
    final confirmed = readInt(member['confirmedCount']);
    final waiting = (submitted - confirmed).clamp(0, 999);
    final total = readInt(member['totalRequiredProofCount'], fallback: readInt(member['requiredSuccessCount']));
    final remaining = readInt(member['remainingRequiredCount']);
    final expected = readString(member['expectedResult']);
    final label = memberExpectedText(expected);
    final color = statusColor(expected);
    final value = total == 0 ? 0.0 : confirmed / total;

    return CMCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CMAvatar(label: name, color: color == CMColors.red ? CMColors.orange : CMColors.blue, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, color: CMColors.text, fontWeight: FontWeight.w900)),
                    if (role == 'OWNER') ...[
                      const SizedBox(width: 6),
                      const CMPill(label: '방장', color: CMColors.blue, background: Color(0xFFDBEAFE), fontSize: 9),
                    ],
                  ],
                ),
              ),
              CMPill(label: label, color: color, background: color.withValues(alpha: 0.12)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: CMProgressBar(value: value, color: CMColors.blue)),
              const SizedBox(width: 12),
              Text('$confirmed / $total회', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: CMColors.text)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MiniStat(label: '제출', value: '$submitted')),
              Expanded(child: _MiniStat(label: '성공 인정', value: '$confirmed')),
              Expanded(child: _MiniStat(label: '확인 대기', value: '$waiting')),
              Expanded(child: _MiniStat(label: '부족', value: '$remaining')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: CMColors.sub, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 12, color: CMColors.text, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.roomId});
  final int roomId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: CMColors.line))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: CMPrimaryButton(
                label: '인증 올리기',
                icon: Icons.upload_rounded,
                onPressed: () => context.push('/rooms/$roomId/submit-proof'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CMOutlineButton(
                label: '인증 확인하기',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => context.push('/rooms/$roomId/proofs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
