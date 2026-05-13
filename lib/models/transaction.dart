enum TransactionType { credit, debit }

enum TransactionStatus { pending, success, failed }

class TransactionItem {
  final String id;
  final double amount;
  final TransactionType type;
  final String purpose;
  final TransactionStatus status;
  final String? reference;
  final DateTime createdAt;

  TransactionItem({
    required this.id,
    required this.amount,
    required this.type,
    required this.purpose,
    required this.status,
    this.reference,
    required this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] ?? json['_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] == 'CREDIT' ? TransactionType.credit : TransactionType.debit,
      purpose: json['purpose'] ?? '',
      status: _parseStatus(json['status']),
      reference: json['reference'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  static TransactionStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
        return TransactionStatus.success;
      case 'FAILED':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }

  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;
}
