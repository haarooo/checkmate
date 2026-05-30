class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderNickname,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int roomId;
  final int senderId;
  final String senderNickname;
  final String content;
  final DateTime createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _readInt(json['id']),
      roomId: _readInt(json['roomId']),
      senderId: _readInt(json['senderId']),
      senderNickname: _readString(json['senderNickname']),
      content: _readString(json['content']),
      createdAt: _readDate(json['createdAt']),
    );
  }

  static int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _readString(dynamic v) => v?.toString() ?? '';

  static DateTime _readDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
