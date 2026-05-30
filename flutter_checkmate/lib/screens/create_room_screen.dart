
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/ui_mappers.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final stakePointController = TextEditingController(text: '10000');

  String proofType = 'DAILY';
  int requiredCount = 2;
  int maxMembers = 5;
  int durationDays = 30;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    stakePointController.dispose();
    super.dispose();
  }

  Future<void> createRoom() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final stakePoint = int.tryParse(stakePointController.text.trim());

    if (title.isEmpty || stakePoint == null || stakePoint <= 0) {
      setState(() => errorMessage = '방 제목과 예치 포인트를 올바르게 입력하세요.');
      return;
    }

    if (durationDays <= 0) {
      setState(() => errorMessage = '미션 기간을 선택해주세요.');
      return;
    }
    if (proofType == 'DAILY' && durationDays < 30) {
      setState(() => errorMessage = '매일 인증은 최소 30일 이상 진행해야 합니다.');
      return;
    }
    if (proofType == 'WEEKLY' && durationDays < 28) {
      setState(() => errorMessage = '주 단위 인증은 최소 4주 이상 진행해야 합니다.');
      return;
    }

    final count = proofType == 'WEEKLY' ? requiredCount.clamp(1, 7).toInt() : requiredCount;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final room = await ref.read(roomServiceProvider).createRoom(
        title: title,
        description: description,
        durationDays: durationDays,
        deadlineTime: '23:00',
        stakePoint: stakePoint,
        maxMembers: maxMembers,
        proofFrequencyType: proofType,
        requiredProofCount: count,
      );
      if (!mounted) return;
      context.go('/rooms/${room.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = ApiClient.messageFromError(e);
        isLoading = false;
      });
    }
  }

  String _durationLabel() {
    if (proofType == 'WEEKLY') return '${durationDays ~/ 7}주 ($durationDays일)';
    return '$durationDays일';
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
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home'), color: AppColors.textPrimary),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('새 인증방 만들기', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('친구들과 함께 지킬 미션을 설정해요', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.borderLight),
          // ─── 본문 ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 섹션 1: 기본 정보
                  _sectionCard(
                    title: '기본 정보',
                    icon: Icons.edit_outlined,
                    child: Column(
                      children: [
                        _buildTextField('방 제목', '예: 여름 전까지 4주 운동방', titleController),
                        const SizedBox(height: 16),
                        _buildTextField('방 설명 (선택)', '어떤 미션인지 간단히 설명해요', descriptionController, maxLines: 2),
                        const SizedBox(height: 16),
                        _buildDropdownField('모집 인원'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 섹션 2: 미션 기간
                  _sectionCard(
                    title: '미션 기간',
                    icon: Icons.calendar_today_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: _infoBox('미션 시작일', '방장 시작 다음날')),
                          const SizedBox(width: 12),
                          Expanded(child: _infoBox('선택 기간', _durationLabel())),
                        ]),
                        const SizedBox(height: 14),
                        _buildDurationSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 섹션 3: 인증 방식
                  _sectionCard(
                    title: '인증 방식',
                    icon: Icons.track_changes,
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: _buildProofTypeButton('DAILY', '매일 인증')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildProofTypeButton('WEEKLY', '주 단위 인증')),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 15, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  proofType == 'DAILY'
                                      ? '매일 정해진 횟수만큼 인증해요. 멤버 확인을 받아야 성공으로 인정돼요.'
                                      : '한 주 안에 목표 횟수만 채우면 돼요. 멤버 확인을 받아야 성공으로 인정돼요.',
                                  style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 섹션 4: 제출 목표
                  _sectionCard(
                    title: proofType == 'DAILY' ? '하루 제출 목표' : '주간 제출 목표',
                    icon: Icons.check_circle_outline,
                    subtitle: proofType == 'DAILY' ? '매일 이 횟수만큼 인증을 올려야 해요' : '한 주 동안 이 횟수만큼 인증을 올리면 돼요',
                    child: Column(
                      children: [
                        _buildConnectedStepper(),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('인증 마감 시간', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                const Text('23:00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              ]),
                              const Icon(Icons.access_time, color: AppColors.textMuted, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          proofType == 'DAILY' ? '매일 23:00 이후에는 인증을 제출할 수 없어요.' : '주간 미션은 매주 마지막 날 23:00까지 제출할 수 있어요.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 섹션 5: 예치금
                  _sectionCard(
                    title: '예치금',
                    icon: Icons.account_balance_wallet_outlined,
                    child: Column(
                      children: [
                        _buildTextField('예치금 (포인트)', '예: 10000', stakePointController, keyboardType: TextInputType.number),
                        const SizedBox(height: 14),
                        _stakeInfoCard(),
                      ],
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
          // ─── 하단 버튼 ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('인증방 만들기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 섹션 카드 ────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─── 기간 선택 ────────────────────────────────────────────────

  Widget _buildDurationSelector() {
    final options = proofType == 'DAILY' ? [30, 60, 90, 120] : [28, 56, 84, 112];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((days) {
        final isSelected = durationDays == days;
        final label = proofType == 'WEEKLY' ? '${days ~/ 7}주' : '$days일';
        return GestureDetector(
          onTap: () => setState(() => durationDays = days),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Connected Stepper ────────────────────────────────────────

  Widget _buildConnectedStepper() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _stepperButton(Icons.remove, () { if (requiredCount > 1) setState(() => requiredCount--); }),
          Expanded(
            child: Center(
              child: Text('$requiredCount회', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
          ),
          _stepperButton(Icons.add, () {
            final limit = proofType == 'WEEKLY' ? 7 : 10;
            if (requiredCount < limit) setState(() => requiredCount++);
          }),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }

  // ─── 예치금 안내 카드 ──────────────────────────────────────────

  Widget _stakeInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.savings_outlined, size: 15, color: AppColors.primary),
            SizedBox(width: 8),
            Text('예치금은 어떻게 쓰이나요?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ]),
          const SizedBox(height: 10),
          const Text(
            '예치금은 미션 시작 전 맡겨두는 가상 포인트예요.',
            style: TextStyle(fontSize: 12, color: AppColors.primaryDark, height: 1.5),
          ),
          const SizedBox(height: 8),
          ...UiMappers.settlementPolicyTexts.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, height: 1.4))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(UiMappers.virtualPointNoticeText, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ─── 공통 위젯 ────────────────────────────────────────────────

  Widget _infoBox(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surfaceAlt,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }

  Widget _buildDropdownField(String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: maxMembers,
            isExpanded: true,
            items: const [2, 3, 4, 5, 6].map((value) => DropdownMenuItem(value: value, child: Text('$value명', style: const TextStyle(fontSize: 15)))).toList(),
            onChanged: (value) { if (value != null) setState(() => maxMembers = value); },
          ),
        ),
      ),
    ]);
  }

  Widget _buildProofTypeButton(String type, String label) {
    final isSelected = proofType == type;
    return GestureDetector(
      onTap: () => setState(() {
        proofType = type;
        durationDays = type == 'WEEKLY' ? 28 : 30;
        if (type == 'WEEKLY' && requiredCount > 7) requiredCount = 7;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
