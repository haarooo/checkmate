class NotificationModel {
  final int id;
  final int? roomId;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      roomId: json['roomId'] as int?,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
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
