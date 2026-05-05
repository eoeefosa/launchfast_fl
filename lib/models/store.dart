import 'package:flutter/material.dart';
import '../utils/color_mapper.dart';

class Store {
  final String id;
  final String name;
  final String tagline;
  final Color accentColor;
  final String deliveryTime;
  final double rating;
  final bool isOpen;
  final String? adminUsername;
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
    required this.deliveryFee,
    required this.image,
    this.ownerId,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    // accentColor arrives from the backend as a hex string; parse safely using ColorMapper.
    Color parsedColor = const Color(0xFFFF6B2C);
    final colorVal = json['accentColor'];
    if (colorVal is String && colorVal.isNotEmpty) {
      parsedColor = Color(ColorMapper.hexToArgb(colorVal));
    }

    return Store(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? 'Store',
      tagline: json['tagline'] ?? json['description'] ?? '',
      accentColor: parsedColor,
      deliveryTime: json['deliveryTime'] ?? '20-30 min',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      isOpen: json['isOpen'] ?? true,
      adminUsername: json['adminUsername'],
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] ?? '',
      ownerId: json['ownerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      // Serialize Color back to a 6-digit hex string for network/storage.
      'accentColor': '#${ColorMapper.argbToHex(accentColor.toARGB32())}',
      'deliveryTime': deliveryTime,
      'rating': rating,
      'isOpen': isOpen,
      'adminUsername': adminUsername,
      'deliveryFee': deliveryFee,
      'image': image,
      'ownerId': ownerId,
    };
  }

  Store copyWith({
    String? id,
    String? name,
    String? tagline,
    Color? accentColor,
    String? deliveryTime,
    double? rating,
    bool? isOpen,
    String? adminUsername,
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
      deliveryFee: deliveryFee ?? this.deliveryFee,
      image: image ?? this.image,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
