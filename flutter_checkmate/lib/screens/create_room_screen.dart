
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home'), color: const Color(0xFF374151)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('새 인증방 만들기', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    const SizedBox(height: 8),
                    const Text('친구들과 함께할 미션을 설정하세요', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
                    const SizedBox(height: 24),
                    _buildTextField('방 제목', '예: 여름 전까지 4주 운동방', titleController),
                    const SizedBox(height: 20),
                    _buildTextField('방 설명', '친구들과 함께 운동 습관 만들기', descriptionController, maxLines: 3),
                    const SizedBox(height: 20),
                    _buildDropdownField('모집 인원', Icons.people_outline),
                    const SizedBox(height: 20),
                    _buildLabel('미션 기간', Icons.calendar_today_outlined),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _dateBox('미션 시작일', '방장 시작 다음날')),
                        const SizedBox(width: 12),
                        Expanded(child: _dateBox('선택 기간', _durationLabel())),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDurationSelector(),
                    const SizedBox(height: 20),
                    const Text('인증 방식', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: _buildProofTypeButton('DAILY')), const SizedBox(width: 12), Expanded(child: _buildProofTypeButton('WEEKLY'))]),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  proofType == 'DAILY'
                                      ? '매일 정해진 횟수만큼 인증을 제출해야 해요. 최소 30일 이상 진행됩니다.'
                                      : '한 주 안에 정해진 횟수만큼 인증을 제출하면 돼요. 최소 4주 이상 진행됩니다.',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '제출만으로는 성공이 아니며, 멤버 확인이 완료되어야 인정됩니다.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proofType == 'DAILY' ? '하루 제출 목표' : '주간 제출 목표',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          proofType == 'DAILY'
                              ? '매일 이 횟수만큼 인증을 올려야 해요.'
                              : '한 주 동안 이 횟수만큼 인증을 올리면 돼요.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildCounterButton(Icons.remove, () { if (requiredCount > 1) setState(() => requiredCount--); }),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                            child: Text('$requiredCount', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildCounterButton(Icons.add, () {
                          final limit = proofType == 'WEEKLY' ? 7 : 10;
                          if (requiredCount < limit) setState(() => requiredCount++);
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('인증 마감 시간', Icons.access_time),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('23:00', style: TextStyle(fontSize: 16, color: Color(0xFF111827))), Icon(Icons.access_time, color: Color(0xFF9CA3AF))]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proofType == 'DAILY'
                          ? '매일 23:00 이후에는 인증을 제출할 수 없어요.'
                          : '주간 미션은 매주 마지막 날 23:00까지 제출할 수 있어요.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField('내 예치금', '예: 10000', stakePointController, keyboardType: TextInputType.number),
                    const SizedBox(height: 4),
                    const Text('성공하면 돌려받고, 실패하면 성공한 멤버에게 분배될 수 있어요.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 12),
                    _stakeInfoCard(),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : createRoom,
                icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const SizedBox.shrink(),
                label: Text(isLoading ? '생성 중...' : '인증방 만들기', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stakeInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text(
                '예치금은 어떻게 쓰이나요?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '예치금은 미션 시작 전 납부하는 가상 포인트입니다. 성공하면 돌려받고, 실패하면 성공한 멤버에게 분배될 수 있어요.',
            style: TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.5),
          ),
          const SizedBox(height: 10),
          ...UiMappers.settlementPolicyTexts.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
                  Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            UiMappers.virtualPointNoticeText,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }

  Widget _buildDropdownField(String label, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label, icon),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: maxMembers,
            isExpanded: true,
            items: const [2, 3, 4, 5, 6].map((value) => DropdownMenuItem(value: value, child: Text('$value명', style: TextStyle(fontSize: 16)))).toList(),
            onChanged: (value) { if (value != null) setState(() => maxMembers = value); },
          ),
        ),
      ),
    ]);
  }

  Widget _buildLabel(String label, IconData icon) => Row(children: [Icon(icon, size: 18, color: const Color(0xFF6B7280)), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)))]);

  Widget _buildProofTypeButton(String type) {
    final isSelected = proofType == type;
    final label = type == 'DAILY' ? '매일 인증' : '주 단위 인증';
    return GestureDetector(
      onTap: () => setState(() {
        proofType = type;
        durationDays = type == 'WEEKLY' ? 28 : 30;
        if (type == 'WEEKLY' && requiredCount > 7) requiredCount = 7;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB))),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF374151))),
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Icon(icon, size: 20, color: const Color(0xFF374151))),
    );
  }
}
