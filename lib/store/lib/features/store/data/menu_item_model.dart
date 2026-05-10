class ItemOption {
  final String name;
  final double price;

  ItemOption({required this.name, required this.price});

  factory ItemOption.fromJson(Map<String, dynamic> json) {
    return ItemOption(
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}

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
  final bool requiresSoupSelection;
  final int? prepTimeMinutes;
  final bool isReady;
  final int? calories;
  final List<String>? addonIds;
  final List<ItemOption>? sizes;
  final List<ItemOption>? meatOptions;

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
    this.requiresSoupSelection = false,
    this.prepTimeMinutes,
    this.isReady = true,
    this.calories,
    this.addonIds,
    this.sizes,
    this.meatOptions,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? json['_id'] ?? '',
      storeId: json['storeId'] ?? json['restaurantId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'Others',
      image: json['image'] ?? '',
      popular: json['popular'] ?? false,
      isPerPortion: json['isPerPortion'] ?? false,
      isFreeWithSwallow: json['isFreeWithSwallow'] ?? false,
      requiresSoupSelection: json['requiresSoupSelection'] ?? false,
      prepTimeMinutes: json['prepTimeMinutes'],
      isReady: json['isReady'] ?? json['available'] ?? true, // Support both isReady and available
      calories: json['calories'],
      addonIds: json['addonIds'] != null ? List<String>.from(json['addonIds']) : null,
      sizes: json['sizes'] != null
          ? (json['sizes'] as List).map((e) => ItemOption.fromJson(e)).toList()
          : null,
      meatOptions: json['meatOptions'] != null
          ? (json['meatOptions'] as List).map((e) => ItemOption.fromJson(e)).toList()
          : null,
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
      'requiresSoupSelection': requiresSoupSelection,
      'prepTimeMinutes': prepTimeMinutes,
      'isReady': isReady,
      'available': isReady, // For backend compatibility
      'calories': calories,
      'addonIds': addonIds,
      'sizes': sizes?.map((e) => e.toJson()).toList(),
      'meatOptions': meatOptions?.map((e) => e.toJson()).toList(),
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
    bool? requiresSoupSelection,
    int? prepTimeMinutes,
    bool? isReady,
    int? calories,
    List<String>? addonIds,
    List<ItemOption>? sizes,
    List<ItemOption>? meatOptions,
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
      requiresSoupSelection: requiresSoupSelection ?? this.requiresSoupSelection,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      isReady: isReady ?? this.isReady,
      calories: calories ?? this.calories,
      addonIds: addonIds ?? this.addonIds,
      sizes: sizes ?? this.sizes,
      meatOptions: meatOptions ?? this.meatOptions,
    );
  }
}
