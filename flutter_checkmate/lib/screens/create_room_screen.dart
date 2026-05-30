import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../ui/checkmate_ui.dart';

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
  bool loading = false;
  String? errorMessage;

  static const String fixedDeadlineTime = '23:00';

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    stakePointController.dispose();
    super.dispose();
  }

  List<int> get durationOptions => proofType == 'DAILY' ? [30, 60, 90, 120] : [28, 56, 84, 112];

  int get maxRequiredCount => proofType == 'WEEKLY' ? 7 : 10;

  String get durationLabel {
    if (proofType == 'WEEKLY') return '${durationDays ~/ 7}주 ($durationDays일)';
    return '$durationDays일';
  }

  String get proofTypeLabel => proofType == 'DAILY' ? '매일 인증' : '주 단위 인증';

  String get countTitle => proofType == 'DAILY' ? '하루 제출 목표' : '주간 제출 목표';

  String get countSubtitle => proofType == 'DAILY'
      ? '매일 $requiredCount회 인증을 제출해야 해요.'
      : '한 주 동안 $requiredCount회 인증을 제출하면 돼요.';

  void changeProofType(String type) {
    setState(() {
      proofType = type;
      durationDays = type == 'DAILY' ? 30 : 28;
      if (type == 'WEEKLY' && requiredCount > 7) requiredCount = 7;
      if (requiredCount < 1) requiredCount = 1;
    });
  }

  Future<void> createRoom() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final stakePoint = int.tryParse(stakePointController.text.trim());

    if (title.isEmpty || stakePoint == null || stakePoint <= 0) {
      setState(() => errorMessage = '방 제목과 예치 포인트를 올바르게 입력하세요.');
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

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final room = await ref.read(roomServiceProvider).createRoom(
            title: title,
            description: description,
            durationDays: durationDays,
            deadlineTime: fixedDeadlineTime,
            stakePoint: stakePoint,
            maxMembers: maxMembers,
            proofFrequencyType: proofType,
            requiredProofCount: requiredCount.clamp(1, maxRequiredCount),
          );

      if (!mounted) return;
      context.go('/rooms/${room.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e is DioException ? ApiClient.messageFromError(e) : '방 생성에 실패했어요.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          CMTopBar(
            title: '새 인증방 만들기',
            subtitle: '친구들과 함께 지킬 미션을 설정해요.',
            onBack: () => context.canPop() ? context.pop() : context.go('/rooms'),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _HeaderCard(
                  proofTypeLabel: proofTypeLabel,
                  durationLabel: durationLabel,
                  requiredCount: requiredCount,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '기본 정보',
                  icon: Icons.edit_outlined,
                  child: Column(
                    children: [
                      _TextInput(label: '방 제목', hint: '예: 여름 전까지 4주 운동방', controller: titleController),
                      const SizedBox(height: 14),
                      _TextInput(label: '방 설명 (선택)', hint: '어떤 미션인지 간단히 설명해요', controller: descriptionController, maxLines: 2),
                      const SizedBox(height: 14),
                      _MemberDropdown(value: maxMembers, onChanged: (v) => setState(() => maxMembers = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: '미션 기간',
                  icon: Icons.calendar_today_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: _InfoBox(label: '미션 시작일', value: '방장 시작 다음날')),
                        const SizedBox(width: 12),
                        Expanded(child: _InfoBox(label: '선택 기간', value: durationLabel)),
                      ]),
                      const SizedBox(height: 14),
                      _DurationSelector(
                        options: durationOptions,
                        selected: durationDays,
                        weekly: proofType == 'WEEKLY',
                        onSelected: (days) => setState(() => durationDays = days),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: '인증 방식',
                  icon: Icons.track_changes_rounded,
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _ProofTypeButton(label: '매일 인증', selected: proofType == 'DAILY', onTap: () => changeProofType('DAILY'))),
                        const SizedBox(width: 10),
                        Expanded(child: _ProofTypeButton(label: '주 단위 인증', selected: proofType == 'WEEKLY', onTap: () => changeProofType('WEEKLY'))),
                      ]),
                      const SizedBox(height: 12),
                      _BlueNotice(
                        text: proofType == 'DAILY'
                            ? '매일 정해진 횟수만큼 인증해요. 멤버 확인을 받아야 성공으로 인정돼요.'
                            : '한 주 안에 목표 횟수만 채우면 돼요. 멤버 확인을 받아야 성공으로 인정돼요.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: countTitle,
                  icon: Icons.check_circle_outline_rounded,
                  subtitle: proofType == 'DAILY' ? '매일 이 횟수만큼 인증을 올려요.' : '한 주 동안 이 횟수만큼 인증을 올려요.',
                  child: Column(
                    children: [
                      _CountStepper(
                        value: requiredCount,
                        min: 1,
                        max: maxRequiredCount,
                        onChanged: (v) => setState(() => requiredCount = v),
                      ),
                      const SizedBox(height: 14),
                      _DeadlineBox(deadlineTime: fixedDeadlineTime, proofType: proofType),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          countSubtitle,
                          style: const TextStyle(fontSize: 11, color: CMColors.sub, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: '예치금',
                  icon: Icons.account_balance_wallet_outlined,
                  child: Column(
                    children: [
                      _TextInput(
                        label: '예치금 (포인트)',
                        hint: '예: 10000',
                        controller: stakePointController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      const _StakeInfoCard(),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _ErrorBox(message: errorMessage!),
                ],
                const SizedBox(height: 110),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: CMPrimaryButton(
              label: '인증방 만들기',
              icon: Icons.add_rounded,
              onPressed: createRoom,
              loading: loading,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.proofTypeLabel,
    required this.durationLabel,
    required this.requiredCount,
  });

  final String proofTypeLabel;
  final String durationLabel;
  final int requiredCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: CMColors.blue.withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('새로운 인증방을\n설정해 보세요', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.22)),
              SizedBox(height: 8),
              Text('규칙은 시작 전까지 한눈에 확인할 수 있어요.', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
          Container(
            width: 66,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              const Icon(Icons.flag_rounded, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(durationLabel, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              Text('$proofTypeLabel $requiredCount회', textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Color(0xFFDBEAFE), fontSize: 8, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child, this.subtitle});
  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return CMCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 17, color: CMColors.blue),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: CMColors.text)),
        ]),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Text(subtitle!, style: const TextStyle(fontSize: 11, color: CMColors.sub, fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(height: 15),
        child,
      ]),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CMColors.sub)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: CMColors.muted, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CMColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CMColors.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CMColors.blue, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        ),
      ),
    ]);
  }
}

class _MemberDropdown extends StatelessWidget {
  const _MemberDropdown({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('모집 인원', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CMColors.sub)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: CMColors.line)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            items: const [2, 3, 4, 5, 6]
                .map((v) => DropdownMenuItem<int>(value: v, child: Text('$v명', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    ]);
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: CMColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: CMColors.sub, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: CMColors.text, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  const _DurationSelector({
    required this.options,
    required this.selected,
    required this.weekly,
    required this.onSelected,
  });

  final List<int> options;
  final int selected;
  final bool weekly;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: options.map((days) {
        final isSelected = days == selected;
        final label = weekly ? '${days ~/ 7}주' : '$days일';
        return GestureDetector(
          onTap: () => onSelected(days),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? CMColors.blue : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: isSelected ? CMColors.blue : CMColors.line),
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : CMColors.sub)),
          ),
        );
      }).toList(),
    );
  }
}

class _ProofTypeButton extends StatelessWidget {
  const _ProofTypeButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? CMColors.blue : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? CMColors.blue : CMColors.line),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: selected ? Colors.white : CMColors.sub)),
      ),
    );
  }
}

class _BlueNotice extends StatelessWidget {
  const _BlueNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: const Color(0xFFF8FBFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCFE1FF))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: CMColors.blue),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: CMColors.blue, height: 1.45, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: CMColors.line)),
      child: Row(children: [
        _StepperButton(icon: Icons.remove_rounded, enabled: value > min, onTap: () => onChanged(value - 1)),
        Expanded(
          child: Center(
            child: Text('$value회', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: CMColors.text)),
          ),
        ),
        _StepperButton(icon: Icons.add_rounded, enabled: value < max, onTap: () => onChanged(value + 1)),
      ]),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: CMColors.line),
        ),
        child: Icon(icon, color: enabled ? CMColors.blue : CMColors.muted, size: 22),
      ),
    );
  }
}

class _DeadlineBox extends StatelessWidget {
  const _DeadlineBox({required this.deadlineTime, required this.proofType});
  final String deadlineTime;
  final String proofType;

  @override
  Widget build(BuildContext context) {
    final message = proofType == 'DAILY'
        ? '매일 23:00 이후에는 인증을 제출할 수 없어요.'
        : '주간 미션은 매주 마지막 날 23:00까지 제출할 수 있어요.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: CMColors.line)),
      child: Row(children: [
        const Icon(Icons.access_time_rounded, color: CMColors.muted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('인증 마감 시간', style: TextStyle(fontSize: 10, color: CMColors.sub, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(deadlineTime, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: CMColors.text)),
            const SizedBox(height: 3),
            Text(message, style: const TextStyle(fontSize: 10, color: CMColors.muted, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _StakeInfoCard extends StatelessWidget {
  const _StakeInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFF8FBFF), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFCFE1FF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Row(children: [
          Icon(Icons.savings_outlined, size: 16, color: CMColors.blue),
          SizedBox(width: 8),
          Text('예치금은 어떻게 쓰이나요?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: CMColors.blue)),
        ]),
        SizedBox(height: 10),
        Text('예치금은 미션 시작 전 맡겨두는 가상 포인트예요.', style: TextStyle(fontSize: 11, color: CMColors.text, height: 1.45, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('• 성공자는 정산 보상을 받을 수 있어요.\n• 실패자는 정책에 따라 예치금을 잃거나 일부 환불받아요.\n• 현재 포인트는 서비스 내 가상 포인트입니다.',
            style: TextStyle(fontSize: 11, color: CMColors.sub, height: 1.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: CMColors.redBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFECACA))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 17, color: CMColors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: CMColors.red, fontSize: 12, fontWeight: FontWeight.w800))),
      ]),
    );
  }
}
