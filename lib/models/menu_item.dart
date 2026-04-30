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
      id: json['id'] ?? '',
      storeId: json['storeId'] ?? json['store'] ?? '',
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
}
