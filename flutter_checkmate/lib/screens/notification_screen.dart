import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../models/notification_model.dart';
import '../ui/checkmate_ui.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  late Future<List<NotificationModel>> future;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    future = ref.read(notificationServiceProvider).getNotifications();
  }

  void _refresh() {
    setState(() => future = ref.read(notificationServiceProvider).getNotifications());
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationServiceProvider).markAllAsRead();
    _refresh();
  }

  Future<void> _open(NotificationModel notification) async {
    if (!notification.read) {
      await ref.read(notificationServiceProvider).markAsRead(notification.id);
    }
    if (!mounted) return;
    if (notification.roomId != null) {
      context.push('/rooms/${notification.roomId}');
    } else {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      bottom: CMBottomNav(
        current: 'my',
        onTap: (key) {
          if (key == 'home') context.go('/home');
          if (key == 'rooms') context.go('/rooms');
          if (key == 'proof') context.go('/proof');
          if (key == 'my') context.go('/mypage');
        },
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 92),
      child: FutureBuilder<List<NotificationModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CMColors.blue));
          }
          if (snapshot.hasError) {
            return CMErrorView(message: '알림을 불러오지 못했어요.', onRetry: _refresh);
          }

          final notifications = snapshot.data ?? [];
          final unreadCount = notifications.where((e) => !e.read).length;
          final visible = _filter(notifications);
          final unread = visible.where((e) => !e.read).toList();
          final read = visible.where((e) => e.read).toList();

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: CMColors.blue,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                CMTopBar(
                  title: '알림 센터',
                  onBack: () => context.canPop() ? context.pop() : context.go('/mypage'),
                  actions: [
                    IconButton(
                      onPressed: _markAllRead,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: CMColors.text),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _NotificationTabs(current: tab, unreadCount: unreadCount, onChanged: (v) => setState(() => tab = v)),
                const SizedBox(height: 24),
                Text('읽지 않은 알림 ${unread.length}', style: const TextStyle(fontSize: 14, color: CMColors.text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (unread.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('새 알림이 없어요.', style: TextStyle(fontSize: 12, color: CMColors.sub)),
                  )
                else
                  CMCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: unread.map((n) => _NotificationTile(notification: n, onTap: () => _open(n))).toList(),
                    ),
                  ),
                const SizedBox(height: 26),
                const Text('이전 알림', style: TextStyle(fontSize: 14, color: CMColors.text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (read.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('이전 알림이 없어요.', style: TextStyle(fontSize: 12, color: CMColors.sub)),
                  )
                else
                  CMCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: read.take(6).map((n) => _NotificationTile(notification: n, onTap: () => _open(n))).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<NotificationModel> _filter(List<NotificationModel> items) {
    if (tab == 1) return items.where((e) => e.type == 'PROOF_SUBMITTED' || e.type == 'PROOF_CONFIRMED').toList();
    if (tab == 2) return items.where((e) => e.type == 'ROOM_STARTED').toList();
    if (tab == 3) return items.where((e) => e.type == 'ROOM_SETTLED').toList();
    return items;
  }
}

class _NotificationTabs extends StatelessWidget {
  const _NotificationTabs({
    required this.current,
    required this.unreadCount,
    required this.onChanged,
  });

  final int current;
  final int unreadCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = ['전체', '인증', '미션방', '정산'];
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = current == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: selected ? CMColors.blue : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                    child: Text(labels[i], style: TextStyle(color: selected ? Colors.white : CMColors.sub, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                  if (i == 0 && unreadCount > 0)
                    Positioned(
                      top: -8,
                      right: 13,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: CMColors.red, borderRadius: BorderRadius.circular(99)),
                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _color(notification.type);
    final icon = _icon(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CMColors.line))),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(notification.title, style: const TextStyle(fontSize: 14, color: CMColors.text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: CMColors.sub, height: 1.35)),
                const SizedBox(height: 5),
                Text(timeAgo(notification.createdAt), style: const TextStyle(fontSize: 10, color: CMColors.muted)),
              ]),
            ),
            if (!notification.read)
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: CMColors.blue, shape: BoxShape.circle))
            else
              const Icon(Icons.chevron_right_rounded, color: CMColors.muted),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'PROOF_SUBMITTED':
        return Icons.image_rounded;
      case 'PROOF_CONFIRMED':
        return Icons.verified_rounded;
      case 'ROOM_STARTED':
        return Icons.flag_rounded;
      case 'ROOM_SETTLED':
        return Icons.toll_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'PROOF_SUBMITTED':
        return CMColors.purple;
      case 'PROOF_CONFIRMED':
        return CMColors.green;
      case 'ROOM_STARTED':
        return CMColors.blue;
      case 'ROOM_SETTLED':
        return CMColors.orange;
      default:
        return CMColors.blue;
    }
  }
}
