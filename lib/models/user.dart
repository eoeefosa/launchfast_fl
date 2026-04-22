class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? address;
  final String? phone;
  final double walletBalance;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.address,
    this.phone,
    required this.walletBalance,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      address: json['address'],
      phone: json['phone'],
      walletBalance: (json['walletBalance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
      'walletBalance': walletBalance,
    };
  }
}
