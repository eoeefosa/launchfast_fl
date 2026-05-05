class MenuItem {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final String category; // 'Rice' | 'Swallow' | 'Soup' | 'Others'
  final String image;
  final bool popular;
  final bool isPerPortion;
  final bool isFreeWithSwallow;
  final int? prepTimeMinutes;
  final bool isReady;
  final int? calories;
  final List<String>? addonIds;
  final List<ItemSize> sizes;
  final List<ItemExtra> extras;

  MenuItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    this.popular = false,
    this.isPerPortion = false,
    this.isFreeWithSwallow = false,
    this.prepTimeMinutes,
    this.isReady = true,
    this.calories,
    this.addonIds,
    this.sizes = const [],
    this.extras = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? 
               (json['store'] is Map ? json['store']['_id']?.toString() : json['store']?.toString()) ?? 
               (json['restaurantId'] is Map ? json['restaurantId']['_id']?.toString() : json['restaurantId']?.toString()) ?? '',
      name: json['name'] ?? 'Unknown Item',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0) is num 
          ? (json['price'] as num).toDouble() 
          : 0.0,
      category: json['category'] ?? 'Others',
      image: json['image'] ?? '',
      popular: json['popular'] ?? false,
      isPerPortion: json['isPerPortion'] ?? false,
      isFreeWithSwallow: json['isFreeWithSwallow'] ?? false,
      prepTimeMinutes: json['prepTimeMinutes'],
      isReady: json['isReady'] ?? true,
      calories: json['calories'],
      addonIds: json['addonIds'] != null ? List<String>.from(json['addonIds']) : null,
      sizes: json['sizes'] != null 
          ? (json['sizes'] as List).map((i) => ItemSize.fromJson(i)).toList()
          : const [],
      extras: json['extras'] != null 
          ? (json['extras'] as List).map((i) => ItemExtra.fromJson(i)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': image,
      'popular': popular,
      'isPerPortion': isPerPortion,
      'isFreeWithSwallow': isFreeWithSwallow,
      'prepTimeMinutes': prepTimeMinutes,
      'isReady': isReady,
      'calories': calories,
      'addonIds': addonIds,
      'sizes': sizes.map((i) => i.toJson()).toList(),
      'extras': extras.map((i) => i.toJson()).toList(),
    };
  }

  MenuItem copyWith({
    String? id,
    String? storeId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? image,
    bool? popular,
    bool? isPerPortion,
    bool? isFreeWithSwallow,
    int? prepTimeMinutes,
    bool? isReady,
    int? calories,
    List<String>? addonIds,
    List<ItemSize>? sizes,
    List<ItemExtra>? extras,
  }) {
    return MenuItem(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      image: image ?? this.image,
      popular: popular ?? this.popular,
      isPerPortion: isPerPortion ?? this.isPerPortion,
      isFreeWithSwallow: isFreeWithSwallow ?? this.isFreeWithSwallow,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      isReady: isReady ?? this.isReady,
      calories: calories ?? this.calories,
      addonIds: addonIds ?? this.addonIds,
      sizes: sizes ?? this.sizes,
      extras: extras ?? this.extras,
    );
  }
}

class ItemSize {
  final String id;
  final String name;
  final double price;

  ItemSize({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ItemSize.fromJson(Map<String, dynamic> json) {
    return ItemSize(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0) is num 
          ? (json['price'] as num).toDouble() 
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}

class ItemExtra {
  final String name;
  final double price;

  ItemExtra({
    required this.name,
    required this.price,
  });

  factory ItemExtra.fromJson(Map<String, dynamic> json) {
    return ItemExtra(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0) is num 
          ? (json['price'] as num).toDouble() 
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}
