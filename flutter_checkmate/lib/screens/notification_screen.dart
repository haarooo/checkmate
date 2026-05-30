import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_colors.dart';
import '../models/notification_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  bool _showReadOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await ref.read(notificationServiceProvider).getNotifications();
      if (mounted) setState(() => _notifications = items);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel n) async {
    if (n.read) {
      if (n.roomId != null) context.push('/rooms/${n.roomId}');
      return;
    }

    // 낙관적 업데이트
    setState(() {
      _notifications = _notifications.map((item) {
        return item.id == n.id
            ? item.copyWith(read: true, readAt: DateTime.now())
            : item;
      }).toList();
    });

    try {
      await ref.read(notificationServiceProvider).markAsRead(n.id);
    } catch (e) {
      if (mounted) {
        // 실패 시 롤백
        setState(() {
          _notifications = _notifications.map((item) {
            return item.id == n.id ? n : item;
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.messageFromError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return; // 실패 시 방 이동 없이 종료
    }

    if (mounted && n.roomId != null) {
      context.push('/rooms/${n.roomId}');
    }
  }

  Future<void> _markAllAsRead() async {
    final hasUnread = _notifications.any((n) => !n.read);
    if (!hasUnread) return;

    try {
      await ref.read(notificationServiceProvider).markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            return n.read ? n : n.copyWith(read: true, readAt: DateTime.now());
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.messageFromError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<NotificationModel> get _filtered {
    if (_showReadOnly) return _notifications.where((n) => n.read).toList();
    return _notifications;
  }

  bool get _hasUnread => _notifications.any((n) => !n.read);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _header(),
          _filterBar(),
          Container(height: 1, color: AppColors.border),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              '알림',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: _hasUnread ? _markAllAsRead : null,
            child: Text(
              '모두 읽음',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _hasUnread ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _filterChip(label: '전체', selected: !_showReadOnly, onTap: () => setState(() => _showReadOnly = false)),
          const SizedBox(width: 8),
          _filterChip(label: '읽은 알림', selected: _showReadOnly, onTap: () => setState(() => _showReadOnly = true)),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filtered;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                '아직 알림이 없어요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                '미션 시작, 인증 제출, 정산 알림이\n여기에 표시돼요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) => _notificationCard(items[index]),
      ),
    );
  }

  Widget _notificationCard(NotificationModel n) {
    final isUnread = !n.read;
    return GestureDetector(
      onTap: () => _markAsRead(n),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? const Color(0xFFBFDBFE) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 읽음 여부 파란 점
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 20),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnread ? AppColors.primary : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 타입 아이콘
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconBgColor(n.type),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(_typeEmoji(n.type), style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 본문
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(n.createdAt),
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'ROOM_STARTED':    return '🚀';
      case 'PROOF_SUBMITTED': return '📷';
      case 'PROOF_CONFIRMED': return '✅';
      case 'ROOM_SETTLED':    return '🏆';
      default:                return '🔔';
    }
  }

  Color _iconBgColor(String type) {
    switch (type) {
      case 'ROOM_STARTED':    return const Color(0xFFEFF6FF);
      case 'PROOF_SUBMITTED': return const Color(0xFFF0FDF4);
      case 'PROOF_CONFIRMED': return const Color(0xFFF0FDF4);
      case 'ROOM_SETTLED':    return const Color(0xFFFFFBEB);
      default:                return const Color(0xFFF3F4F6);
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}
