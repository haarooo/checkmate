import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_colors.dart';
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
      if (mounted) setState(() { _error = ApiClient.messageFromError(e); _loading = false; });
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
        String message;
        if (e is DioException) {
          if (e.response?.statusCode == 403) {
            message = '내 인증은 직접 확인할 수 없어요.';
          } else if (e.response?.statusCode == 409) {
            message = '이미 확인한 인증입니다.';
          } else {
            message = ApiClient.messageFromError(e);
          }
        } else {
          message = ApiClient.messageFromError(e);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/rooms/${widget.roomId}'),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('인증 피드', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text(
                          '인증을 확인하고 친구의 성공을 도와주세요',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: AppColors.errorSoft, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline, size: 36, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loadFeed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: const Text('다시 시도', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
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
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library_outlined, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('아직 올라온 인증이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('첫 번째 인증을 올려보세요!', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isMine ? AppColors.primary.withValues(alpha: 0.4) : AppColors.borderLight,
          width: item.isMine ? 1.5 : 1,
        ),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(item, isConfirmed),
          const SizedBox(height: 14),
          if (item.fileUrl != null) ...[
            _buildFilePreview(item),
            const SizedBox(height: 14),
          ],
          if (item.content != null && item.content!.isNotEmpty) ...[
            Text(
              item.content!,
              style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
          ],
          _buildActionArea(item, isConfirmed),
        ],
      ),
    );
  }

  Widget _buildCardHeader(ProofFeedItemModel item, bool isConfirmed) {
    final initial = item.nickname.isNotEmpty ? item.nickname[0] : '?';

    // 헤더 pill: isMine이면 숨김, canConfirm이면 주황색, 그 외 완료/대기 상태
    String? pillText;
    Color pillBg = AppColors.primarySoft;
    Color pillFg = AppColors.primaryDark;
    IconData? pillIcon;

    if (item.isMine) {
      pillText = null; // 내 인증은 헤더 pill 없음
    } else if (item.canConfirm) {
      pillText = '멤버 확인 필요';
      pillBg = AppColors.warningSoft;
      pillFg = AppColors.warning;
      pillIcon = Icons.notification_important_outlined;
    } else if (item.alreadyConfirmedByMe) {
      pillText = '내가 확인했어요';
      pillBg = AppColors.successSoft;
      pillFg = AppColors.successDark;
      pillIcon = Icons.check_circle;
    } else if (isConfirmed) {
      pillText = '확인 완료';
      pillBg = AppColors.successSoft;
      pillFg = AppColors.successDark;
      pillIcon = Icons.check_circle;
    } else {
      pillText = '확인 대기';
      pillBg = AppColors.primarySoft;
      pillFg = AppColors.primaryDark;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(item.nickname, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                        ),
                        if (item.isMine) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                            child: const Text('내 인증', style: TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (pillText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pillIcon != null) ...[
                            Icon(pillIcon, color: pillFg, size: 11),
                            const SizedBox(width: 3),
                          ],
                          Text(pillText, style: TextStyle(color: pillFg, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(_formatDate(item.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_outline, size: 52, color: AppColors.successDark),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        _resolveFileUrl(item.fileUrl!),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.textMuted)),
        ),
      ),
    );
  }

  Widget _buildActionArea(ProofFeedItemModel item, bool isConfirmed) {
    final countText = '${item.confirmationCount}/${item.requiredConfirmationCount}';

    if (item.canConfirm) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => _confirmProof(item.proofId),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 16),
              const SizedBox(width: 8),
              Text('확인하기  ·  $countText', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (item.alreadyConfirmedByMe) {
      return _statusBox(
        icon: Icons.check_circle,
        iconColor: AppColors.successDark,
        bgColor: AppColors.successSoft,
        borderColor: const Color(0xFFBBF7D0),
        text: '내가 확인했어요',
        textColor: AppColors.successDark,
        countText: countText,
        countColor: AppColors.successDark,
      );
    }

    if (isConfirmed) {
      return _statusBox(
        icon: Icons.check_circle,
        iconColor: AppColors.successDark,
        bgColor: AppColors.successSoft,
        borderColor: const Color(0xFFBBF7D0),
        text: '확인 완료',
        textColor: AppColors.successDark,
        countText: countText,
        countColor: AppColors.successDark,
      );
    }

    if (item.isMine) {
      return _statusBox(
        icon: Icons.info_outline,
        iconColor: AppColors.primaryDark,
        bgColor: AppColors.primarySoft,
        borderColor: const Color(0xFFBFDBFE),
        text: '멤버 확인을 기다리고 있어요',
        textColor: AppColors.primaryDark,
        countText: countText,
        countColor: AppColors.primaryDark,
      );
    }

    return _statusBox(
      icon: Icons.hourglass_empty,
      iconColor: AppColors.textMuted,
      bgColor: AppColors.cardBorder,
      borderColor: AppColors.border,
      text: '확인 대기 중',
      textColor: AppColors.textSecondary,
      countText: countText,
      countColor: AppColors.textMuted,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500))),
          Text(countText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: countColor)),
        ],
      ),
    );
  }
}
