import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';

class CartItem {
  final String id;
  final MenuItem menuItem;
  int quantity;
  final List<String>? extras;
  final Map<String, int>? selectedMeats;
  final Map<String, int>? selectedSides;
  final Map<String, int>? selectedDrinks;
  final Map<String, int>? selectedAddons;
  final List<dynamic>? selectedMeatsDetails;
  final List<dynamic>? selectedSidesDetails;
  final List<dynamic>? selectedDrinksDetails;
  final List<dynamic>? selectedAddonsDetails;
  final String? selectedSizeId;
  final Map<String, dynamic>? selectedSoup;
  final double? lineTotal;

  CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.extras,
    this.selectedMeats,
    this.selectedSides,
    this.selectedDrinks,
    this.selectedAddons,
    this.selectedMeatsDetails,
    this.selectedSidesDetails,
    this.selectedDrinksDetails,
    this.selectedAddonsDetails,
    this.selectedSizeId,
    this.selectedSoup,
    this.lineTotal,
  });

  double get effectiveLineTotal {
    if (lineTotal != null) return lineTotal!;
    double optionsCost = 0.0;
    void sumOptions(List<dynamic>? details) {
      if (details == null) return;
      for (final dynamic element in details) {
        if (element is Map) {
          final price = (element['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = (element['quantity'] as num?)?.toInt() ?? 1;
          optionsCost += price * quantity;
        }
      }
    }
    sumOptions(selectedMeatsDetails);
    sumOptions(selectedSidesDetails);
    sumOptions(selectedDrinksDetails);
    sumOptions(selectedAddonsDetails);
    double soupPrice = 0.0;
    if (selectedSoup != null) {
      soupPrice = (selectedSoup!['price'] as num?)?.toDouble() ?? 0.0;
    }
    return (menuItem.price + optionsCost + soupPrice) * quantity;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    return CartItem(
      id: rawId?.toString() ?? '',
      menuItem: MenuItem.fromJson(json['menuItem']),
      quantity: json['quantity'] ?? 1,
      extras: json['extras'] != null ? List<String>.from(json['extras']) : null,
      selectedMeats: json['selectedMeats'] != null
          ? Map<String, int>.from(json['selectedMeats'])
          : null,
      selectedSides: json['selectedSides'] != null
          ? Map<String, int>.from(json['selectedSides'])
          : null,
      selectedDrinks: json['selectedDrinks'] != null
          ? Map<String, int>.from(json['selectedDrinks'])
          : null,
      selectedAddons: json['selectedAddons'] != null
          ? Map<String, int>.from(json['selectedAddons'])
          : null,
      selectedMeatsDetails: json['selectedMeatsDetails'],
      selectedSidesDetails: json['selectedSidesDetails'],
      selectedDrinksDetails: json['selectedDrinksDetails'],
      selectedAddonsDetails: json['selectedAddonsDetails'],
      selectedSizeId: json['selectedSizeId']?.toString(),
      selectedSoup: json['selectedSoup'] != null && json['selectedSoup'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['selectedSoup'])
          : null,
      lineTotal: (json['lineTotal'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'extras': extras,
      'selectedMeats': selectedMeats,
      'selectedSides': selectedSides,
      'selectedDrinks': selectedDrinks,
      'selectedAddons': selectedAddons,
      'selectedMeatsDetails': selectedMeatsDetails,
      'selectedSidesDetails': selectedSidesDetails,
      'selectedDrinksDetails': selectedDrinksDetails,
      'selectedAddonsDetails': selectedAddonsDetails,
      'selectedSizeId': selectedSizeId,
      'selectedSoup': selectedSoup,
      'lineTotal': lineTotal,
    };
  }
}
