import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/auth_controller.dart';
import '../models/chat_message_model.dart';

class RoomChatScreen extends ConsumerStatefulWidget {
  const RoomChatScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends ConsumerState<RoomChatScreen> {
  final List<ChatMessageModel> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isConnected = false;
  bool _connectionLost = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    // 화면 이탈 시 WebSocket 연결을 반드시 끊는다.
    ref.read(chatServiceProvider).disconnect();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── 초기화 ────────────────────────────────────────────────────

  Future<void> _initChat() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isConnected = false;
      _connectionLost = false;
    });

    final chatService = ref.read(chatServiceProvider);

    // 1단계: REST로 기존 메시지 조회
    try {
      final messages = await chatService.getMessages(widget.roomId);
      if (!mounted) return; // getMessages 완료 후 mounted 체크
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiClient.messageFromError(e);
        _isLoading = false;
      });
      return; // REST 실패 시 STOMP 연결 시도하지 않음
    }

    // 2단계: STOMP WebSocket 연결
    // connect()는 activate()를 호출하고 바로 반환된다.
    // 실제 연결 완료는 onConnected 콜백으로 전달된다.
    await chatService.connect(
      roomId: widget.roomId,
      onMessage: (msg) {
        if (!mounted) return; // STOMP onMessage 후 mounted 체크
        setState(() => _messages.add(msg));
        _scrollToBottom();
      },
      onError: () {
        if (!mounted) return; // STOMP onError 후 mounted 체크
        setState(() {
          _isConnected = false;
          _connectionLost = true;
        });
      },
      onConnected: () {
        if (!mounted) return; // STOMP onConnected 후 mounted 체크
        setState(() => _isConnected = true);
      },
    );
  }

  // ─── 메시지 전송 ────────────────────────────────────────────────

  void _sendMessage() {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;

    final chatService = ref.read(chatServiceProvider);

    // 조건 3: STOMP 연결 완료 전 전송 차단 → Snackbar 안내
    if (!chatService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('채팅 서버에 연결 중입니다. 잠시 후 다시 시도해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _inputController.clear();

    // 조건 4: 로컬에 즉시 추가하지 않음.
    // 서버가 broadcast하면 onMessage 콜백으로 수신하여 리스트에 추가됨.
    // 중복 표시 방지.
    chatService.send(widget.roomId, content);
  }

  // ─── 스크롤 ─────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // postFrameCallback 실행 시 mounted 체크
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── 빌드 ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(authControllerProvider).currentUser?.id;

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
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                    onPressed: () {
                      if (context.canPop()) context.pop();
                      else context.go('/rooms/${widget.roomId}');
                    },
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('채팅', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            )
          else if (_errorMessage != null && _messages.isEmpty)
            Expanded(child: _errorBox())
          else ...[
            _connectionStatusBar(),
            Expanded(
              child: _messages.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg.senderId == currentUserId;
                        return _MessageBubble(message: msg, isMe: isMe);
                      },
                    ),
            ),
            _inputBar(),
          ],
        ],
      ),
    );
  }

  // ─── 서브 위젯 ──────────────────────────────────────────────────

  Widget _connectionStatusBar() {
    if (_isConnected) return const SizedBox.shrink();

    if (_connectionLost) {
      return Container(
        width: double.infinity,
        color: const Color(0xFFFEF2F2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Row(
          children: [
            Icon(Icons.wifi_off, size: 14, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '채팅 연결이 끊겼어요. 다시 입장하거나 잠시 후 시도해 주세요.',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      );
    }

    // 아직 연결 중 (STOMP onConnected 미수신)
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7ED),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFFF97316),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '채팅 서버 연결 중...',
            style: TextStyle(fontSize: 12, color: Color(0xFFF97316)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 48, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text(
            '아직 메시지가 없어요.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            '첫 메시지를 보내보세요!',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 44, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFEF4444)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요',
                hintStyle:
                    const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 메시지 버블 ──────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 상대방 메시지: 닉네임 표시
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 4),
              child: Text(
                message.senderNickname,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 상대방: 아바타
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    message.senderNickname.isNotEmpty
                        ? message.senderNickname[0]
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // 말풍선
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF3B82F6)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : const Color(0xFF111827),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $displayHour:$minute';
  }
}
