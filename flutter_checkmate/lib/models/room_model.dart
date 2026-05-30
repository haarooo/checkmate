class RoomSummaryModel {
  const RoomSummaryModel({
    required this.id,
    required this.title,
    required this.status,
    required this.maxMembers,
    required this.stakePoint,
    required this.currentMemberCount,
    required this.myRole,
    required this.proofFrequencyType,
    required this.requiredProofCount,
    this.inviteCode,
    this.inviteLinkToken,
    this.description,
  });

  final int id;
  final String title;
  final String status;
  final int maxMembers;
  final int stakePoint;
  final int currentMemberCount;
  final String myRole;
  final String proofFrequencyType;
  final int requiredProofCount;
  final String? inviteCode;
  final String? inviteLinkToken;
  final String? description;

  int get memberCount => currentMemberCount;

  factory RoomSummaryModel.fromJson(Map<String, dynamic> json) {
    return RoomSummaryModel(
      id: _readInt(json['roomId'] ?? json['id']),
      title: _readString(json['title']),
      status: _readString(json['status']),
      maxMembers: _readInt(json['maxMembers']),
      stakePoint: _readInt(json['stakePoint']),
      currentMemberCount: _readInt(json['currentMemberCount']),
      myRole: _readString(json['myRole']),
      proofFrequencyType: _readString(json['proofFrequencyType']),
      requiredProofCount: _readInt(json['requiredProofCount']),
      inviteCode: _readNullableString(json['inviteCode']),
      inviteLinkToken: _readNullableString(json['inviteLinkToken']),
      description: _readNullableString(json['description']),
    );
  }
}

class RoomDetailModel {
  const RoomDetailModel({
    required this.id,
    required this.title,
    required this.status,
    required this.durationDays,
    required this.deadlineTime,
    required this.targetRate,
    required this.stakePoint,
    required this.maxMembers,
    required this.potPoint,
    required this.currentMemberCount,
    required this.myRole,
    required this.proofFrequencyType,
    required this.requiredProofCount,
    this.description,
    this.inviteCode,
    this.inviteLinkToken,
    this.missionStartDate,
    this.missionEndDate,
  });

  final int id;
  final String title;
  final String? description;
  final String status;
  final String? inviteCode;
  final String? inviteLinkToken;
  final int durationDays;
  final String deadlineTime;
  final int targetRate;
  final int stakePoint;
  final int maxMembers;
  final int potPoint;
  final DateTime? missionStartDate;
  final DateTime? missionEndDate;
  final int currentMemberCount;
  final String myRole;
  final String proofFrequencyType;
  final int requiredProofCount;

  factory RoomDetailModel.fromJson(Map<String, dynamic> json) {
    return RoomDetailModel(
      id: _readInt(json['roomId'] ?? json['id']),
      title: _readString(json['title']),
      description: _readNullableString(json['description']),
      status: _readString(json['status']),
      inviteCode: _readNullableString(json['inviteCode']),
      inviteLinkToken: _readNullableString(json['inviteLinkToken']),
      durationDays: _readInt(json['durationDays']),
      deadlineTime: _readString(json['deadlineTime']),
      targetRate: _readInt(json['targetRate'], defaultValue: 80),
      stakePoint: _readInt(json['stakePoint']),
      maxMembers: _readInt(json['maxMembers']),
      potPoint: _readInt(json['potPoint']),
      missionStartDate: _readNullableDate(json['missionStartDate']),
      missionEndDate: _readNullableDate(json['missionEndDate']),
      currentMemberCount: _readInt(json['currentMemberCount']),
      myRole: _readString(json['myRole']),
      proofFrequencyType: _readString(json['proofFrequencyType']),
      requiredProofCount: _readInt(json['requiredProofCount']),
    );
  }
}

class RoomMemberModel {
  const RoomMemberModel({
    required this.userId,
    required this.nickname,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.stakedPoint,
    this.stakedAt,
  });

  final int userId;
  final String nickname;
  final String role;
  final String status;
  final DateTime joinedAt;
  final int stakedPoint;
  final DateTime? stakedAt;

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    return RoomMemberModel(
      userId: _readInt(json['userId']),
      nickname: _readString(json['nickname']),
      role: _readString(json['role']),
      status: _readString(json['status']),
      joinedAt: _readNullableDate(json['joinedAt']) ?? DateTime(0),
      stakedPoint: _readInt(json['stakedPoint']),
      stakedAt: _readNullableDate(json['stakedAt']),
    );
  }
}

class RoomInvitePreviewModel {
  const RoomInvitePreviewModel({
    required this.roomId,
    required this.title,
    required this.status,
    required this.durationDays,
    required this.deadlineTime,
    required this.targetRate,
    required this.stakePoint,
    required this.maxMembers,
    required this.currentMemberCount,
    required this.joinable,
    required this.proofFrequencyType,
    required this.requiredProofCount,
    this.description,
  });

  final int roomId;
  final String title;
  final String? description;
  final String status;
  final int durationDays;
  final String deadlineTime;
  final int targetRate;
  final int stakePoint;
  final int maxMembers;
  final int currentMemberCount;
  final bool joinable;
  final String proofFrequencyType;
  final int requiredProofCount;

  factory RoomInvitePreviewModel.fromJson(Map<String, dynamic> json) {
    return RoomInvitePreviewModel(
      roomId: _readInt(json['roomId'] ?? json['id']),
      title: _readString(json['title']),
      description: _readNullableString(json['description']),
      status: _readString(json['status']),
      durationDays: _readInt(json['durationDays']),
      deadlineTime: _readString(json['deadlineTime']),
      targetRate: _readInt(json['targetRate'], defaultValue: 80),
      stakePoint: _readInt(json['stakePoint']),
      maxMembers: _readInt(json['maxMembers']),
      currentMemberCount: _readInt(json['currentMemberCount']),
      joinable: _readBool(json['joinable']),
      proofFrequencyType: _readString(json['proofFrequencyType']),
      requiredProofCount: _readInt(json['requiredProofCount']),
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
