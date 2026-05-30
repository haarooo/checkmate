class PointWalletModel {
  const PointWalletModel({required this.balance});

  final int balance;

  factory PointWalletModel.fromJson(Map<String, dynamic> json) {
    return PointWalletModel(balance: (json['balance'] as num?)?.toInt() ?? 0);
  }
}

class PointLedgerModel {
  const PointLedgerModel({
    required this.id,
    required this.amount,
    required this.balanceAfter,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final int amount;
  final int balanceAfter;
  final String type;
  final String description;
  final DateTime createdAt;

  factory PointLedgerModel.fromJson(Map<String, dynamic> json) {
    return PointLedgerModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
