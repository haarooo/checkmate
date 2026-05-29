import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
import '../core/utils/ui_mappers.dart';
import '../models/settlement_model.dart';

class SettlementResultScreen extends ConsumerStatefulWidget {
  const SettlementResultScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<SettlementResultScreen> createState() =>
      _SettlementResultScreenState();
}

class _SettlementResultScreenState
    extends ConsumerState<SettlementResultScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  SettlementModel? _settlement;

  static final _numFmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result =
          await ref.read(roomServiceProvider).getSettlement(widget.roomId);
      if (!mounted) return;
      setState(() {
        _settlement = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiClient.messageFromError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                    onPressed: () {
                      if (context.canPop()) context.pop();
                      else context.go('/home');
                    },
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('정산 결과', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 44, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFEF4444)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final s = _settlement!;
    final currentUserId =
        ref.read(authControllerProvider).currentUser?.id;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _resultHeaderCard(s),
                const SizedBox(height: 16),
                _summaryCard(s),
                const SizedBox(height: 24),
                const Text(
                  '멤버별 결과',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                ...s.members.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _memberCard(m, isMe: m.userId == currentUserId),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                '홈으로 가기',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 전체 결과 헤더 ───────────────────────────────────────────────

  Widget _resultHeaderCard(SettlementModel s) {
    final isAllSuccess = s.failedCount == 0;
    final isAllFailed = s.successCount == 0;

    final Color bg;
    final Color border;
    final Color iconColor;
    final IconData icon;
    final String title;
    final String subtitle;

    if (isAllSuccess) {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      iconColor = const Color(0xFF22C55E);
      icon = Icons.emoji_events_outlined;
      title = '전원 성공';
      subtitle = '모든 멤버가 미션을 완료했어요. 예치금과 보너스를 받아요.';
    } else if (isAllFailed) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      iconColor = const Color(0xFFEF4444);
      icon = Icons.sentiment_dissatisfied_outlined;
      title = '전원 실패';
      subtitle = '아쉽지만 목표를 달성하지 못했어요. 예치금의 70%가 환불돼요.';
    } else {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      iconColor = const Color(0xFF3B82F6);
      icon = Icons.check_circle_outline;
      title = '일부 성공';
      subtitle = '성공한 멤버가 실패 멤버의 예치금을 나눠 받아요.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 요약 카드 ────────────────────────────────────────────────────

  Widget _summaryCard(SettlementModel s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _summaryRow('총 예치금', '${_numFmt.format(s.totalPotPoint)}P'),
          const SizedBox(height: 10),
          _summaryRow('성공 인원', '${s.successCount}명'),
          const SizedBox(height: 10),
          _summaryRow('실패 인원', '${s.failedCount}명'),
          const SizedBox(height: 10),
          _summaryRow('성공 기준', '인증 80% 이상 확인'),
          if (s.systemFeePoint > 0) ...[
            const SizedBox(height: 10),
            _summaryRow(
              '시스템 수수료',
              '${_numFmt.format(s.systemFeePoint)}P',
              valueColor: const Color(0xFFEF4444),
            ),
          ],
          if (s.systemBonusPoint > 0) ...[
            const SizedBox(height: 10),
            _summaryRow(
              '전원 성공 보너스',
              '+${_numFmt.format(s.systemBonusPoint)}P',
              valueColor: const Color(0xFF22C55E),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // ─── 멤버 결과 카드 ────────────────────────────────────────────────

  Widget _memberCard(SettlementMemberModel m, {required bool isMe}) {
    final isSuccess = m.resultStatus == 'SUCCESS';
    final badgeColor = isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final badgeLabel = isSuccess ? '성공' : '실패';
    final rewardLabel = isSuccess ? '+${_numFmt.format(m.rewardPoint)}P' : '0P';
    final rewardColor = isSuccess ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF);
    final bgColor = isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final borderColor = isMe
        ? const Color(0xFF3B82F6)
        : (isSuccess ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA));
    final progressValue = m.requiredSuccessCount > 0
        ? (m.confirmedCount / m.requiredSuccessCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isMe ? 1.5 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                UiMappers.initialFromName(m.nickname),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? '${m.nickname} (나)' : m.nickname,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                      child: Text(badgeLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                    valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '확인 ${m.confirmedCount}/${m.requiredSuccessCount}회  (${m.proofRate.toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    Text(
                      rewardLabel,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rewardColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
