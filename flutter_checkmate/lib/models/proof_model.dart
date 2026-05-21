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
      id: (json['id'] as num).toInt(),
      roomId: (json['roomId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      proofDate: DateTime.parse(json['proofDate'] as String),
      status: json['status'] as String,
      content: json['content'] as String?,
      fileUrl: json['fileUrl'] as String?,
    );
  }
}
