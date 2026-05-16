import 'dart:ui';

class Store {
  final String id;
  final String name;
  final String tagline;
  final String accentColor;
  final String deliveryTime;
  final double rating;
  final bool isOpen;
  final double deliveryFee;
  final double priorityFee;
  final String image;
  final String? ownerId;
  final bool isApproved;

  Store({
    required this.id,
    required this.name,
    required this.tagline,
    required this.accentColor,
    required this.deliveryTime,
    required this.rating,
    required this.isOpen,
    required this.deliveryFee,
    this.priorityFee = 1000.0,
    required this.image,
    this.ownerId,
    this.isApproved = true, // Default to true for backward compatibility with static data
  });

  /// Parsed [Color] from the hex [accentColor] string.
  /// The UI should use this getter instead of parsing the hex manually.
  Color get color => Color(int.parse(accentColor.replaceFirst('#', '0xFF')));

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Store',
      tagline: json['tagline']?.toString() ?? json['description']?.toString() ?? '',
      accentColor: json['accentColor']?.toString() ?? '#FF6B2C',
      deliveryTime: json['deliveryTime']?.toString() ?? '30-45 min',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      isOpen: json['isOpen'] ?? false,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      priorityFee: (json['priorityFee'] as num?)?.toDouble() ?? 1000.0,
      image: json['image']?.toString() ?? '',
      ownerId: json['ownerId']?.toString(),
      isApproved: json['isApproved'] ?? false,
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
      'deliveryFee': deliveryFee,
      'priorityFee': priorityFee,
      'image': image,
      'ownerId': ownerId,
      'isApproved': isApproved,
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
    double? deliveryFee,
    double? priorityFee,
    String? image,
    String? ownerId,
    bool? isApproved,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      accentColor: accentColor ?? this.accentColor,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      priorityFee: priorityFee ?? this.priorityFee,
      image: image ?? this.image,
      ownerId: ownerId ?? this.ownerId,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
