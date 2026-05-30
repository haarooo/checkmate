import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/ui_mappers.dart';
import '../models/settlement_model.dart';

class SettlementResultScreen extends ConsumerStatefulWidget {
  const SettlementResultScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<SettlementResultScreen> createState() => _SettlementResultScreenState();
}

class _SettlementResultScreenState extends ConsumerState<SettlementResultScreen> {
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
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await ref.read(roomServiceProvider).getSettlement(widget.roomId);
      if (!mounted) return;
      setState(() { _settlement = result; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = ApiClient.messageFromError(e); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text('정산 결과', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.borderLight),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 72, height: 72,
                decoration: const BoxDecoration(color: AppColors.errorSoft, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline, size: 36, color: AppColors.error)),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 32)),
                  child: const Text('다시 시도', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final s = _settlement!;
    final isAllSuccess = s.failedCount == 0;
    final isAllFailed = s.successCount == 0;
    final currentUserId = ref.read(authControllerProvider).currentUser?.id;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _resultHeroCard(s, isAllSuccess: isAllSuccess, isAllFailed: isAllFailed),
                const SizedBox(height: 16),
                _summaryCard(s, isAllSuccess: isAllSuccess, isAllFailed: isAllFailed),
                const SizedBox(height: 20),
                const Text('멤버별 결과', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...s.members.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _memberCard(m, isMe: m.userId == currentUserId, isAllFailed: isAllFailed, isAllSuccess: isAllSuccess),
                )),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        // ─── 하단 버튼 ────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.borderLight))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: const Text('홈으로 가기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Result Hero Card ─────────────────────────────────────────

  Widget _resultHeroCard(SettlementModel s, {required bool isAllSuccess, required bool isAllFailed}) {
    if (isAllSuccess) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Stack(
            children: [
              Positioned(right: -30, top: -30, child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                      child: const Text('전원 성공', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
                        SizedBox(width: 10),
                        Text('전원 성공했어요!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('모든 멤버가 목표를 달성해 예치금과 보너스를 받아요.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isAllFailed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            Container(width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.sentiment_dissatisfied_outlined, size: 28, color: AppColors.error)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('전원 실패', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.error)),
                  ]),
                  SizedBox(height: 6),
                  Text('전원 실패했어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('모든 멤버가 목표를 달성하지 못했어요.\n일부 패널티 후 남은 포인트가 환불돼요.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 일부 성공
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(
          children: [
            Positioned(right: -30, top: -30, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                    child: const Text('일부 성공', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 14),
                  const Text('일부 성공했어요!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('성공한 멤버들이 실패한 멤버의 예치금을 나눠 받아요.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Summary Card ─────────────────────────────────────────────

  Widget _summaryCard(SettlementModel s, {required bool isAllSuccess, required bool isAllFailed}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('총 예치금', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('${_numFmt.format(s.totalPotPoint)}P', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metricItem('${s.successCount}명', '성공', AppColors.successDark)),
              Container(width: 1, height: 40, color: AppColors.borderLight),
              Expanded(child: _metricItem('${s.failedCount}명', '실패', s.failedCount > 0 ? AppColors.error : AppColors.textMuted)),
              Container(width: 1, height: 40, color: AppColors.borderLight),
              Expanded(child: _metricItem('${s.requiredSuccessCount}회', '성공 기준', AppColors.primary)),
            ],
          ),
          // 보너스 / 패널티 (항상 표시)
          if (isAllSuccess) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            _summaryRow(
              Icons.star_rounded,
              '전원 성공 보너스',
              s.systemBonusPoint > 0 ? '+${_numFmt.format(s.systemBonusPoint)}P' : '0P',
              valueColor: s.systemBonusPoint > 0 ? AppColors.successDark : AppColors.textMuted,
            ),
          ],
          if (isAllFailed) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            _summaryRow(
              Icons.shield_outlined,
              '시스템 패널티',
              s.systemFeePoint > 0 ? '-${_numFmt.format(s.systemFeePoint)}P' : '0P',
              valueColor: s.systemFeePoint > 0 ? AppColors.error : AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricItem(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    ]);
  }

  Widget _summaryRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(children: [
      Icon(icon, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
    ]);
  }

  // ─── Member Card ──────────────────────────────────────────────

  Widget _memberCard(SettlementMemberModel m, {required bool isMe, required bool isAllFailed, bool isAllSuccess = false}) {
    final isSuccess = m.resultStatus == 'SUCCESS';
    final badgeColor = isSuccess ? AppColors.successDark : AppColors.error;
    final badgeBg = isSuccess ? AppColors.successSoft : AppColors.errorSoft;
    final resultLabel = isSuccess ? '성공' : '실패';
    final borderColor = isMe ? AppColors.primary : (isSuccess ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA));
    final progress = m.requiredSuccessCount > 0
        ? (m.confirmedCount / m.requiredSuccessCount).clamp(0.0, 1.0)
        : 0.0;

    // 보상 표기
    final String rewardLabel;
    final String rewardCaption;
    final Color rewardColor;
    if (isAllFailed) {
      rewardLabel = '환불 ${_numFmt.format(m.rewardPoint)}P';
      rewardCaption = '패널티 차감 후 환불';
      rewardColor = AppColors.textMuted;
    } else if (isSuccess) {
      rewardLabel = '+${_numFmt.format(m.rewardPoint)}P';
      rewardCaption = isAllSuccess ? '예치금 반환 + 보너스' : '정산 보상';
      rewardColor = AppColors.successDark;
    } else {
      rewardLabel = '0P';
      rewardCaption = '보상 없음';
      rewardColor = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isMe ? 1.5 : 1),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Center(child: Text(UiMappers.initialFromName(m.nickname), style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800, fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(m.nickname, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                          child: const Text('나', style: TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(resultLabel, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text('성공 인정 ${m.confirmedCount}/${m.requiredSuccessCount}회  (${m.proofRate.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('인증 제출 ${m.submittedCount}회', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(rewardLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: rewardColor)),
                Text(rewardCaption, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
