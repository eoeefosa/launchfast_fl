import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  final List<String>? extras;
  final Map<String, int>? selectedMeats;
  final bool hasSalad;
  final Map<String, int>? selectedAddons;

  CartItem({
    required this.menuItem,
    required this.quantity,
    this.extras,
    this.selectedMeats,
    this.hasSalad = false,
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
      hasSalad: json['hasSalad'] ?? false,
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
      'hasSalad': hasSalad,
      'selectedAddons': selectedAddons,
    };
  }
}
