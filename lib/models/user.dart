class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? address;
  final String? phone;
  final double walletBalance;
  final String role; // 'user', 'store_owner', 'rider', 'admin'
  final String? adminStore;
  final bool emailVerified;
  final bool phoneVerified;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.address,
    this.phone,
    required this.walletBalance,
    required this.role,
    this.adminStore,
    this.emailVerified = false,
    this.phoneVerified = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      address: json['address'],
      phone: json['phone'],
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      role: json['role'] ?? 'user',
      adminStore: json['adminStore'],
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
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
      'role': role,
      'adminStore': adminStore,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
    };
  }
}
