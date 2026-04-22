class Rider {
  final String id;
  final String name;
  final String phoneNumber;
  final int capacity;
  final double? walletBalance;

  Rider({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.capacity,
    this.walletBalance,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      capacity: json['capacity'],
      walletBalance: json['walletBalance'] != null ? (json['walletBalance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'capacity': capacity,
      'walletBalance': walletBalance,
    };
  }
}
