class ProofSubmitResponseModel {
  const ProofSubmitResponseModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.proofDate,
    required this.status,
    this.content,
    this.fileUrl,
  });

  final int id;
  final int roomId;
  final int userId;
  final DateTime proofDate;
  final String status;
  final String? content;
  final String? fileUrl;

  factory ProofSubmitResponseModel.fromJson(Map<String, dynamic> json) {
    return ProofSubmitResponseModel(
      id: _readInt(json['id']),
      roomId: _readInt(json['roomId']),
      userId: _readInt(json['userId']),
      proofDate: DateTime.tryParse(json['proofDate']?.toString() ?? '') ?? DateTime.now(),
      status: _readString(json['status']),
      content: _readNullableString(json['content']),
      fileUrl: _readNullableString(json['fileUrl']),
    );
  }
}

class ProofFeedItemModel {
  const ProofFeedItemModel({
    required this.proofId,
    required this.roomId,
    required this.userId,
    required this.nickname,
    required this.status,
    required this.proofDate,
    required this.createdAt,
    required this.confirmationCount,
    required this.requiredConfirmationCount,
    required this.canConfirm,
    required this.isMine,
    required this.alreadyConfirmedByMe,
    this.content,
    this.fileUrl,
    this.fileOriginalName,
    this.fileContentType,
    this.confirmedAt,
  });

  final int proofId;
  final int roomId;
  final int userId;
  final String nickname;
  final String status;
  final DateTime proofDate;
  final DateTime createdAt;
  final int confirmationCount;
  final int requiredConfirmationCount;
  final bool canConfirm;
  final bool isMine;
  final bool alreadyConfirmedByMe;
  final String? content;
  final String? fileUrl;
  final String? fileOriginalName;
  final String? fileContentType;
  final DateTime? confirmedAt;

  factory ProofFeedItemModel.fromJson(Map<String, dynamic> json) {
    return ProofFeedItemModel(
      proofId: _readInt(json['proofId'] ?? json['id']),
      roomId: _readInt(json['roomId']),
      userId: _readInt(json['userId']),
      nickname: _readString(json['nickname']),
      status: _readString(json['status']),
      proofDate: DateTime.tryParse(json['proofDate']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      confirmationCount: _readInt(json['confirmationCount']),
      requiredConfirmationCount: _readInt(json['requiredConfirmationCount'], defaultValue: 1),
      canConfirm: _readBool(json['canConfirm']),
      isMine: _readBool(json['isMine']),
      alreadyConfirmedByMe: _readBool(json['alreadyConfirmedByMe']),
      content: _readNullableString(json['content']),
      fileUrl: _readNullableString(json['fileUrl']),
      fileOriginalName: _readNullableString(json['fileOriginalName']),
      fileContentType: _readNullableString(json['fileContentType']),
      confirmedAt: _readNullableDate(json['confirmedAt']),
    );
  }
}

int _readInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

String _readString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

String? _readNullableString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _readNullableDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

bool _readBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return defaultValue;
}
