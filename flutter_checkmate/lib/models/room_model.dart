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
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      status: json['status'] as String,
      maxMembers: (json['maxMembers'] as num).toInt(),
      stakePoint: (json['stakePoint'] as num).toInt(),
      currentMemberCount: (json['currentMemberCount'] as num).toInt(),
      myRole: json['myRole'] as String,
      proofFrequencyType: json['proofFrequencyType'] as String,
      requiredProofCount: (json['requiredProofCount'] as num).toInt(),
      inviteCode: json['inviteCode'] as String?,
      inviteLinkToken: json['inviteLinkToken'] as String?,
      description: json['description'] as String?,
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
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      inviteCode: json['inviteCode'] as String?,
      inviteLinkToken: json['inviteLinkToken'] as String?,
      durationDays: (json['durationDays'] as num).toInt(),
      deadlineTime: json['deadlineTime'] as String,
      targetRate: (json['targetRate'] as num).toInt(),
      stakePoint: (json['stakePoint'] as num).toInt(),
      maxMembers: (json['maxMembers'] as num).toInt(),
      potPoint: (json['potPoint'] as num).toInt(),
      missionStartDate: json['missionStartDate'] == null
          ? null
          : DateTime.parse(json['missionStartDate'] as String),
      missionEndDate: json['missionEndDate'] == null
          ? null
          : DateTime.parse(json['missionEndDate'] as String),
      currentMemberCount: (json['currentMemberCount'] as num).toInt(),
      myRole: json['myRole'] as String,
      proofFrequencyType: json['proofFrequencyType'] as String,
      requiredProofCount: (json['requiredProofCount'] as num).toInt(),
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
  });

  final int userId;
  final String nickname;
  final String role;
  final String status;
  final DateTime joinedAt;

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    return RoomMemberModel(
      userId: (json['userId'] as num).toInt(),
      nickname: json['nickname'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
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
      roomId: (json['roomId'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      durationDays: (json['durationDays'] as num).toInt(),
      deadlineTime: json['deadlineTime'] as String,
      targetRate: (json['targetRate'] as num).toInt(),
      stakePoint: (json['stakePoint'] as num).toInt(),
      maxMembers: (json['maxMembers'] as num).toInt(),
      currentMemberCount: (json['currentMemberCount'] as num).toInt(),
      joinable: json['joinable'] as bool,
      proofFrequencyType: json['proofFrequencyType'] as String,
      requiredProofCount: (json['requiredProofCount'] as num).toInt(),
    );
  }
}
