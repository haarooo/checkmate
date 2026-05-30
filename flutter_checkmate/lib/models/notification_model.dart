class NotificationModel {
  const NotificationModel({
    required this.id,
    this.roomId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  final int id;
  final int? roomId;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      roomId: (json['roomId'] as num?)?.toInt(),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? read, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      roomId: roomId,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
