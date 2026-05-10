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
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      storeId: json['storeId'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      image: json['image'],
      popular: json['popular'] ?? false,
      isPerPortion: json['isPerPortion'] ?? false,
      isFreeWithSwallow: json['isFreeWithSwallow'] ?? false,
      prepTimeMinutes: json['prepTimeMinutes'],
      isReady: json['isReady'] ?? true,
      calories: json['calories'],
      addonIds: json['addonIds'] != null ? List<String>.from(json['addonIds']) : null,
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
    );
  }
}
