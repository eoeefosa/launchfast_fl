enum GiftCardStatus { active, used, expired }

class GiftCard {
  final String id;
  final String code;
  final double amount;
  final GiftCardStatus status;
  final DateTime createdAt;
  final DateTime? usedAt;
  final DateTime? expiresAt;

  GiftCard({
    required this.id,
    required this.code,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.usedAt,
    this.expiresAt,
  });

  bool get isActive => status == GiftCardStatus.active;
  bool get isUsed => status == GiftCardStatus.used;
  bool get isExpired => status == GiftCardStatus.expired;

  factory GiftCard.fromJson(Map<String, dynamic> json) {
    GiftCardStatus parseStatus(String? s) {
      switch (s?.toUpperCase()) {
        case 'USED':
          return GiftCardStatus.used;
        case 'EXPIRED':
          return GiftCardStatus.expired;
        default:
          return GiftCardStatus.active;
      }
    }

    return GiftCard(
      id: json['id'] ?? json['_id'] ?? '',
      code: json['code'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }
}
