import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProofFeedScreen extends StatelessWidget {
  final int roomId;

  const ProofFeedScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/rooms/$roomId'),
                    ),
                  ],
                ),
                const Text('인증 피드', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('여름 전까지 4주 운동방', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildProofCard(
                  initial: '이',
                  name: 'member_124909',
                  time: '2시간 전',
                  content: '하체 운동 40분 완료! 스쿼트 3세트, 런지 3세트 완료했어요. 오늘은 특히 힘들었지만 뿌듯합니다 💪',
                  hasImage: true,
                  status: 'SUBMITTED',
                  confirmCount: '0/1',
                  showConfirmButton: true,
                ),
                const SizedBox(height: 16),
                _buildProofCard(
                  initial: '박',
                  name: 'tester3',
                  time: '6시간 전',
                  content: '러닝머신 30분 완료! 5km 달렸습니다',
                  hasVideo: true,
                  status: 'CONFIRMED',
                  confirmCount: '1/1',
                  confirmedBy: 'owner_124909',
                ),
                const SizedBox(height: 16),
                _buildProofCard(
                  initial: '김',
                  name: 'owner_124909',
                  time: '7시간 전',
                  content: '닭가슴살 샐러드 식단 인증! 단백질 200g 섭취 완료',
                  hasImage: true,
                  status: 'MY_PROOF',
                  confirmCount: '0/1',
                ),
                const SizedBox(height: 16),
                _buildProofCard(
                  initial: '이',
                  name: 'member_124909',
                  time: '8시간 전',
                  content: '아침 조깅 5km 완료! 오늘도 화이팅',
                  hasImage: false,
                  status: 'CONFIRMED',
                  confirmCount: '1/1',
                  confirmedBy: 'tester3',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard({
    required String initial,
    required String name,
    required String time,
    required String content,
    bool hasImage = false,
    bool hasVideo = false,
    required String status,
    required String confirmCount,
    String? confirmedBy,
    bool showConfirmButton = false,
  }) {
    Color statusColor;
    String statusText;
    IconData? statusIcon;

    if (status == 'CONFIRMED') {
      statusColor = const Color(0xFF22C55E);
      statusText = '확인완료';
      statusIcon = Icons.check_circle;
    } else if (status == 'MY_PROOF') {
      statusColor = const Color(0xFF3B82F6);
      statusText = '제출됨';
      statusIcon = null;
    } else {
      statusColor = const Color(0xFF3B82F6);
      statusText = '제출됨';
      statusIcon = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'MY_PROOF' ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
          width: status == 'MY_PROOF' ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: initial == '이'
                        ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
                        : initial == '박'
                            ? [const Color(0xFF22C55E), const Color(0xFF10B981)]
                            : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (status == 'MY_PROOF') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '나',
                                  style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (statusIcon != null) ...[
                                Icon(statusIcon, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                statusText,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasImage || hasVideo) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: hasVideo
                      ? [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)]
                      : initial == '김'
                          ? [const Color(0xFFFED7AA), const Color(0xFFFECDD3)]
                          : [const Color(0xFFDFE9FF), const Color(0xFFDDD6FE)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasVideo
                      ? const Color(0xFF86EFAC)
                      : initial == '김'
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFBFDBFE),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    hasVideo ? Icons.play_circle_outline : Icons.image_outlined,
                    size: 48,
                    color: hasVideo
                        ? const Color(0xFF16A34A)
                        : initial == '김'
                            ? const Color(0xFFF97316)
                            : const Color(0xFF3B82F6),
                  ),
                  if (hasVideo)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '2:34',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          if (showConfirmButton)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('확인하기', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const Text('확인', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 2),
                      Text(confirmCount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                    ],
                  ),
                ),
              ],
            )
          else if (status == 'CONFIRMED')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$confirmedBy님이 확인했어요',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF166534)),
                    ),
                  ),
                  Text(confirmCount, style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '내 인증은 직접 확인할 수 없어요',
                      style: TextStyle(fontSize: 14, color: Color(0xFF2563EB)),
                    ),
                  ),
                  Text(confirmCount, style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
