class Store {
  final String id;
  final String name;
  final String tagline;
  final String accentColor;
  final String deliveryTime;
  final double rating;
  final bool isOpen;
  final String? adminUsername;
  final String? adminPassword;
  final double deliveryFee;
  final String image;
  final String? ownerId;

  Store({
    required this.id,
    required this.name,
    required this.tagline,
    required this.accentColor,
    required this.deliveryTime,
    required this.rating,
    required this.isOpen,
    this.adminUsername,
    this.adminPassword,
    required this.deliveryFee,
    required this.image,
    this.ownerId,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      tagline: json['tagline'],
      accentColor: json['accentColor'],
      deliveryTime: json['deliveryTime'],
      rating: (json['rating'] as num).toDouble(),
      isOpen: json['isOpen'] ?? false,
      adminUsername: json['adminUsername'],
      adminPassword: json['adminPassword'],
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      image: json['image'],
      ownerId: json['ownerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'accentColor': accentColor,
      'deliveryTime': deliveryTime,
      'rating': rating,
      'isOpen': isOpen,
      'adminUsername': adminUsername,
      'adminPassword': adminPassword,
      'deliveryFee': deliveryFee,
      'image': image,
      'ownerId': ownerId,
    };
  }

  Store copyWith({
    String? id,
    String? name,
    String? tagline,
    String? accentColor,
    String? deliveryTime,
    double? rating,
    bool? isOpen,
    String? adminUsername,
    String? adminPassword,
    double? deliveryFee,
    String? image,
    String? ownerId,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      accentColor: accentColor ?? this.accentColor,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      adminUsername: adminUsername ?? this.adminUsername,
      adminPassword: adminPassword ?? this.adminPassword,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      image: image ?? this.image,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
