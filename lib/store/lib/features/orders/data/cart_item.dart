import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  final List<String>? extras;
  final Map<String, int>? selectedMeats;
  final Map<String, int>? selectedSides;
  final Map<String, int>? selectedDrinks;
  final Map<String, int>? selectedAddons;

  CartItem({
    required this.menuItem,
    required this.quantity,
    this.extras,
    this.selectedMeats,
    this.selectedSides,
    this.selectedDrinks,
    this.selectedAddons,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'extras': extras,
      'selectedMeats': selectedMeats,
      'selectedSides': selectedSides,
      'selectedDrinks': selectedDrinks,
      'selectedAddons': selectedAddons,
    };
  }
}
