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
  /// Extra per-order charges configured by the store owner.
  final List<Map<String, dynamic>> charges;
  /// 4-digit PIN required before saving settings. Null means no PIN is set.
  final String? settingsPin;

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
    this.isApproved = true,
    this.charges = const [],
    this.settingsPin,
  });

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
      image: json['image']?.toString() ?? '',
      ownerId: json['ownerId']?.toString(),
      isApproved: json['isApproved'] ?? false,
      charges: (json['charges'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      settingsPin: json['settingsPin']?.toString(),
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
      'charges': charges,
      'settingsPin': settingsPin,
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
    List<Map<String, dynamic>>? charges,
    Object? settingsPin = _sentinel,
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
      charges: charges ?? this.charges,
      settingsPin: identical(settingsPin, _sentinel)
          ? this.settingsPin
          : settingsPin as String?,
    );
  }
}

// Sentinel for copyWith null-passthrough on settingsPin.
const Object _sentinel = Object();
