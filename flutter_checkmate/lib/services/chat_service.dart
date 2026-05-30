import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/chat_message_model.dart';

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

  bool get isConnected => _isConnected;

  Future<List<ChatMessageModel>> getMessages(int roomId) async {
    final response = await _apiClient.dio.get('/api/rooms/$roomId/messages');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> connect({
    required int roomId,
    required void Function(ChatMessageModel) onMessage,
    required void Function() onError,
    required void Function() onConnected,
  }) async {
    disconnect();

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      onError();
      return;
    }

    final wsUrl = '${ApiConstants.baseUrl.replaceFirst('http://', 'ws://')}/ws';

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          if (_stompClient == null) return;

          _isConnected = true;
          onConnected();

          _stompClient?.subscribe(
            destination: '/topic/rooms/$roomId/messages',
            callback: (frame) {
              if (_stompClient == null) return;

              final body = frame.body;
              if (body == null || body.isEmpty) return;
              try {
                final json = jsonDecode(body) as Map<String, dynamic>;
                onMessage(ChatMessageModel.fromJson(json));
              } catch (_) {}
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

  void send(int roomId, String content) {
    if (!_isConnected || _stompClient == null) return;

    _stompClient!.send(
      destination: '/app/rooms/$roomId/messages',
      body: jsonEncode({'content': content}),
    );
  }

  void disconnect() {
    _isConnected = false;
    final client = _stompClient;
    _stompClient = null;
    client?.deactivate();
  }
}
