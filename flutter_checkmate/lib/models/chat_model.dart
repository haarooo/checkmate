class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderNickname,
    required this.content,
    required this.createdAt,
    required this.mine,
  });

  final int id;
  final int roomId;
  final int senderId;
  final String senderNickname;
  final String content;
  final DateTime createdAt;
  final bool mine;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _readInt(json['id'] ?? json['messageId']),
      roomId: _readInt(json['roomId']),
      senderId: _readInt(json['senderId'] ?? json['userId']),
      senderNickname: json['senderNickname']?.toString() ?? json['nickname']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      mine: json['mine'] as bool? ?? false,
    );
  }
}

int _readInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
