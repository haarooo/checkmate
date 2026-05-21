
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';

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

    final durationDays = proofType == 'WEEKLY' ? 28 : 30;
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
            targetRate: 80,
            stakePoint: stakePoint,
            maxMembers: maxMembers,
            proofFrequencyType: proofType,
            requiredProofCount: count,
          );
      if (!mounted) return;
      context.go('/rooms/${room.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
                        Expanded(child: _dateBox('시작일', '시작 후 다음날')),
                        const SizedBox(width: 12),
                        Expanded(child: _dateBox('기간', proofType == 'WEEKLY' ? '4주' : '30일')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('인증 방식', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: _buildProofTypeButton('DAILY')), const SizedBox(width: 12), Expanded(child: _buildProofTypeButton('WEEKLY'))]),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBFDBFE))),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proofType == 'DAILY' ? 'DAILY: 매일 목표 횟수만큼 인증해야 합니다' : 'WEEKLY: 일주일 내에 목표 횟수만큼 인증하면 됩니다',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(proofType == 'DAILY' ? '하루에 몇 번 인증할까요?' : '일주일에 몇 번 인증할까요?', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
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
                    const Text('매일 이 시간 이후에는 인증을 제출할 수 없습니다', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 20),
                    _buildTextField('예치 포인트', '10000', stakePointController, keyboardType: TextInputType.number),
                    const SizedBox(height: 4),
                    const Text('미션 성공 시 예치금이 반환됩니다', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
            padding: const EdgeInsets.all(24),
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

  Widget _dateBox(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Text(value, style: const TextStyle(color: Color(0xFF6B7280))),
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
    return GestureDetector(
      onTap: () => setState(() { proofType = type; if (type == 'WEEKLY' && requiredCount > 7) requiredCount = 7; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB))),
        child: Text(type, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF374151))),
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
