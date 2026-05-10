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
    required this.image,
    this.ownerId,
    this.isApproved = true, // Default to true for backward compatibility with static data
  });

  /// Parsed [Color] from the hex [accentColor] string.
  /// The UI should use this getter instead of parsing the hex manually.
  Color get color => Color(int.parse(accentColor.replaceFirst('#', '0xFF')));

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      tagline: json['tagline'],
      accentColor: json['accentColor'],
      deliveryTime: json['deliveryTime'],
      rating: (json['rating'] as num).toDouble(),
      isOpen: json['isOpen'] ?? false,
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      image: json['image'],
      ownerId: json['ownerId'],
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
      image: image ?? this.image,
      ownerId: ownerId ?? this.ownerId,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
