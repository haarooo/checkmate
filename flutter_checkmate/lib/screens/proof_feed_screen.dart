import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/api_constants.dart';
import '../core/providers/app_providers.dart';
import '../models/proof_model.dart';

class ProofFeedScreen extends ConsumerStatefulWidget {
  final int roomId;

  const ProofFeedScreen({super.key, required this.roomId});

  @override
  ConsumerState<ProofFeedScreen> createState() => _ProofFeedScreenState();
}

class _ProofFeedScreenState extends ConsumerState<ProofFeedScreen> {
  List<ProofFeedItemModel>? _items;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(proofServiceProvider).getProofFeed(widget.roomId);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final items = await ref.read(proofServiceProvider).getProofFeed(widget.roomId);
      if (mounted) setState(() => _items = items);
    } catch (_) {}
  }

  Future<void> _confirmProof(int proofId) async {
    try {
      await ref.read(proofServiceProvider).confirmProof(proofId);
      await _silentRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('확인 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _resolveFileUrl(String fileUrl) {
    if (fileUrl.startsWith('http')) return fileUrl;
    return '${ApiConstants.baseUrl}$fileUrl';
  }

  bool _isVideo(String? contentType, String? fileName) {
    if (contentType != null && contentType.startsWith('video/')) return true;
    if (fileName != null) {
      final lower = fileName.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) return true;
    }
    return false;
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/rooms/${widget.roomId}'),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('인증 피드', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadFeed, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }
    if (_items == null || _items!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(Icons.photo_library_outlined, size: 48, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 12),
                  Text('아직 인증이 없습니다.', style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildProofCard(_items![index]),
      ),
    );
  }

  Widget _buildProofCard(ProofFeedItemModel item) {
    final isConfirmed = item.status == 'CONFIRMED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isMine ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
          width: item.isMine ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(item, isConfirmed),
          const SizedBox(height: 16),
          if (item.fileUrl != null) ...[
            _buildFilePreview(item),
            const SizedBox(height: 16),
          ],
          if (item.content != null && item.content!.isNotEmpty) ...[
            Text(
              item.content!,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 16),
          ],
          _buildActionArea(item, isConfirmed),
        ],
      ),
    );
  }

  Widget _buildCardHeader(ProofFeedItemModel item, bool isConfirmed) {
    final initial = item.nickname.isNotEmpty ? item.nickname[0] : '?';
    final statusColor = isConfirmed ? const Color(0xFF22C55E) : const Color(0xFF3B82F6);
    final statusText = isConfirmed ? '확인완료' : '제출됨';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
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
                      Text(item.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (item.isMine) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('나', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isConfirmed) ...[
                          const Icon(Icons.check_circle, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(_formatDate(item.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview(ProofFeedItemModel item) {
    final isVideo = _isVideo(item.fileContentType, item.fileOriginalName);

    if (isVideo) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_outline, size: 48, color: Color(0xFF16A34A)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        _resolveFileUrl(item.fileUrl!),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: Color(0xFF9CA3AF))),
        ),
      ),
    );
  }

  Widget _buildActionArea(ProofFeedItemModel item, bool isConfirmed) {
    final countText = '${item.confirmationCount}/${item.requiredConfirmationCount}';

    if (item.canConfirm) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmProof(item.proofId),
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
          Column(
            children: [
              const Text('확인', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(countText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
            ],
          ),
        ],
      );
    }

    if (item.alreadyConfirmedByMe) {
      return _statusBox(
        icon: Icons.check_circle,
        iconColor: const Color(0xFF22C55E),
        bgColor: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFBBF7D0),
        text: '내가 확인했어요',
        textColor: const Color(0xFF166534),
        countText: countText,
        countColor: const Color(0xFF16A34A),
      );
    }

    if (isConfirmed) {
      return _statusBox(
        icon: Icons.check_circle,
        iconColor: const Color(0xFF22C55E),
        bgColor: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFBBF7D0),
        text: '확인완료',
        textColor: const Color(0xFF166534),
        countText: countText,
        countColor: const Color(0xFF16A34A),
      );
    }

    if (item.isMine) {
      return _statusBox(
        icon: Icons.info_outline,
        iconColor: const Color(0xFF3B82F6),
        bgColor: const Color(0xFFEFF6FF),
        borderColor: const Color(0xFFBFDBFE),
        text: '내 인증은 직접 확인할 수 없어요',
        textColor: const Color(0xFF2563EB),
        countText: countText,
        countColor: const Color(0xFF3B82F6),
      );
    }

    return _statusBox(
      icon: Icons.hourglass_empty,
      iconColor: const Color(0xFF9CA3AF),
      bgColor: const Color(0xFFF9FAFB),
      borderColor: const Color(0xFFE5E7EB),
      text: '확인 대기 중',
      textColor: const Color(0xFF6B7280),
      countText: countText,
      countColor: const Color(0xFF9CA3AF),
    );
  }

  Widget _statusBox({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String text,
    required Color textColor,
    required String countText,
    required Color countColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: textColor))),
          Text(countText, style: TextStyle(fontSize: 12, color: countColor)),
        ],
      ),
    );
  }
}
