import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../models/chat_message_model.dart';
import '../ui/checkmate_ui.dart';

class RoomChatScreen extends ConsumerStatefulWidget {
  const RoomChatScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends ConsumerState<RoomChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final List<ChatMessageModel> messages = [];

  bool loading = true;
  bool connected = false;
  bool connectError = false;

  @override
  void initState() {
    super.initState();
    _loadAndConnect();
  }

  Future<void> _loadAndConnect() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final loaded = await chatService.getMessages(widget.roomId);
      if (!mounted) return;
      setState(() {
        messages
          ..clear()
          ..addAll(loaded);
        loading = false;
      });
      _scrollToBottom();

      await chatService.connect(
        roomId: widget.roomId,
        onConnected: () {
          if (!mounted) return;
          setState(() {
            connected = true;
            connectError = false;
          });
        },
        onError: () {
          if (!mounted) return;
          setState(() {
            connected = false;
            connectError = true;
          });
        },
        onMessage: (message) {
          if (!mounted) return;
          setState(() => messages.add(message));
          _scrollToBottom();
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        connectError = true;
      });
    }
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final chatService = ref.read(chatServiceProvider);
    if (!chatService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('채팅 연결 중이에요. 잠시 후 다시 보내주세요.')));
      return;
    }

    chatService.send(widget.roomId, text);
    controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    ref.read(chatServiceProvider).disconnect();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 92),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: CMColors.line))),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: '메시지 입력',
                    filled: true,
                    fillColor: CMColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: CMColors.blue, borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          CMTopBar(
            title: '채팅',
            subtitle: connected ? '실시간으로 연결됐어요.' : connectError ? '연결을 확인해 주세요.' : '방 멤버들과 이야기를 나눠요.',
            onBack: () => context.canPop() ? context.pop() : context.go('/rooms/${widget.roomId}'),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: CMColors.blue))
                : messages.isEmpty
                    ? const CMEmptyState(title: '아직 메시지가 없어요', message: '첫 메시지를 남겨 보세요.', icon: Icons.chat_bubble_outline_rounded)
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) => _MessageBubble(message: messages[index]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    // 현재 백엔드 응답만으로는 "내 메시지" 여부가 항상 보장되지 않기 때문에
    // 일단 서버에서 온 senderNickname 기준으로 좌측 카드 형태로 안정적으로 보여준다.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: const BoxConstraints(maxWidth: 275),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CMColors.line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.senderNickname, style: const TextStyle(color: CMColors.sub, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(message.content, style: const TextStyle(color: CMColors.text, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
