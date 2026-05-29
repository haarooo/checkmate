class SettlementModel {
  const SettlementModel({
    required this.settlementId,
    required this.roomId,
    required this.totalPotPoint,
    required this.totalMembers,
    required this.successCount,
    required this.failedCount,
    required this.totalRequiredProofCount,
    required this.requiredSuccessCount,
    required this.systemFeePoint,
    required this.systemBonusPoint,
    required this.settledAt,
    required this.members,
  });

  final int settlementId;
  final int roomId;
  final int totalPotPoint;
  final int totalMembers;
  final int successCount;
  final int failedCount;
  final int totalRequiredProofCount;
  final int requiredSuccessCount;
  final int systemFeePoint;
  final int systemBonusPoint;
  final DateTime? settledAt;
  final List<SettlementMemberModel> members;

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    final membersList = (json['members'] as List<dynamic>? ?? [])
        .map((e) => SettlementMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return SettlementModel(
      settlementId: _readInt(json['settlementId']),
      roomId: _readInt(json['roomId']),
      totalPotPoint: _readInt(json['totalPotPoint']),
      totalMembers: _readInt(json['totalMembers']),
      successCount: _readInt(json['successCount']),
      failedCount: _readInt(json['failedCount']),
      totalRequiredProofCount: _readInt(json['totalRequiredProofCount']),
      requiredSuccessCount: _readInt(json['requiredSuccessCount']),
      systemFeePoint: _readInt(json['systemFeePoint']),
      systemBonusPoint: _readInt(json['systemBonusPoint']),
      settledAt: _readNullableDate(json['settledAt']),
      members: membersList,
    );
  }
}

class SettlementMemberModel {
  const SettlementMemberModel({
    required this.userId,
    required this.nickname,
    required this.resultStatus,
    required this.submittedCount,
    required this.confirmedCount,
    required this.requiredSuccessCount,
    required this.rewardPoint,
    required this.proofRate,
  });

  final int userId;
  final String nickname;
  final String resultStatus; // SUCCESS or FAILED
  final int submittedCount;
  final int confirmedCount;
  final int requiredSuccessCount;
  final int rewardPoint;
  final double proofRate;

  factory SettlementMemberModel.fromJson(Map<String, dynamic> json) {
    return SettlementMemberModel(
      userId: _readInt(json['userId']),
      nickname: _readString(json['nickname']),
      resultStatus: _readString(json['resultStatus']),
      submittedCount: _readInt(json['submittedCount']),
      confirmedCount: _readInt(json['confirmedCount']),
      requiredSuccessCount: _readInt(json['requiredSuccessCount']),
      rewardPoint: _readInt(json['rewardPoint']),
      proofRate: _readDouble(json['proofRate']),
    );
  }
}

int _readInt(dynamic v, {int d = 0}) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? d;
  return d;
}

String _readString(dynamic v) => v?.toString() ?? '';

DateTime? _readNullableDate(dynamic v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

double _readDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
