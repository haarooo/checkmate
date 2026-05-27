import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/chat_message_model.dart';

/// 채팅 REST 조회 + WebSocket/STOMP 연결을 담당하는 서비스.
///
/// StompClient는 이 서비스가 1개만 관리한다.
/// RoomChatScreen dispose 시 반드시 disconnect()를 호출해야 한다.
class ChatService {
  ChatService({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  StompClient? _stompClient;
  bool _isConnected = false;

  /// STOMP 연결 상태.
  /// send() 호출 전 이 값으로 연결 완료 여부를 확인해야 한다.
  bool get isConnected => _isConnected;

  // ─── REST ───────────────────────────────────────────────────────

  /// 특정 방의 최근 채팅 메시지 50건을 오래된 순(ASC)으로 반환한다.
  Future<List<ChatMessageModel>> getMessages(int roomId) async {
    final response = await _apiClient.dio.get('/api/rooms/$roomId/messages');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── STOMP ──────────────────────────────────────────────────────

  /// WebSocket/STOMP 연결을 시작한다.
  ///
  /// 기존 연결이 있으면 먼저 끊고 새로 연결한다.
  /// 연결 완료: [onConnected] 콜백
  /// 새 메시지 수신: [onMessage] 콜백
  /// 연결 오류: [onError] 콜백
  ///
  /// 콜백 안에서는 반드시 mounted 체크 후 setState를 호출해야 한다.
  Future<void> connect({
    required int roomId,
    required void Function(ChatMessageModel) onMessage,
    required void Function() onError,
    required void Function() onConnected,
  }) async {
    // 기존 연결 정리 (화면 재진입·재시도 시 zombie 연결 방지)
    disconnect();

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      onError();
      return;
    }

    final wsUrl =
        ApiConstants.baseUrl.replaceFirst('http://', 'ws://') + '/ws';

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        // STOMP CONNECT 헤더에 JWT 토큰 첨부
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          // disconnect() 이후 콜백이 지연 실행될 경우 방어
          if (_stompClient == null) return;

          _isConnected = true;
          onConnected();

          _stompClient?.subscribe(
            destination: '/topic/rooms/$roomId/messages',
            callback: (frame) {
              // disconnect() 이후 메시지가 지연 도착할 경우 방어
              if (_stompClient == null) return;

              final body = frame.body;
              if (body == null || body.isEmpty) return;
              try {
                final json = jsonDecode(body) as Map<String, dynamic>;
                onMessage(ChatMessageModel.fromJson(json));
              } catch (_) {
                // 파싱 실패는 조용히 무시
              }
            },
          );
        },
        onDisconnect: (_) {
          _isConnected = false;
        },
        onWebSocketError: (_) {
          _isConnected = false;
          onError();
        },
        onStompError: (_) {
          _isConnected = false;
          onError();
        },
      ),
    );

    _stompClient!.activate();
  }

  /// STOMP로 메시지를 전송한다.
  ///
  /// 연결이 완료되지 않은 상태([isConnected] == false)이면 아무것도 하지 않는다.
  /// 호출부에서 반드시 [isConnected]를 확인한 뒤 호출해야 한다.
  void send(int roomId, String content) {
    if (!_isConnected || _stompClient == null) return;
    _stompClient!.send(
      destination: '/app/rooms/$roomId/messages',
      body: jsonEncode({'content': content}),
    );
  }

  /// STOMP 연결을 끊는다.
  ///
  /// RoomChatScreen.dispose()에서 반드시 호출해야 한다.
  /// 내부 클라이언트 참조를 null로 만들어 zombie 연결 및 콜백 실행을 방지한다.
  void disconnect() {
    _isConnected = false;
    final client = _stompClient;
    _stompClient = null; // null 먼저 → onConnect/onMessage 콜백 방어
    client?.deactivate();
  }
}
