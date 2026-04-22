import 'dart:convert';
import 'menu_item.dart';

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
    // Handle menuItem (Map OR String)
    final menuItemData = json['menuItem'] is String
        ? jsonDecode(json['menuItem'])
        : json['menuItem'];

    // Handle selectedMeats (Map OR String)
    final meatsData = json['selectedMeats'] is String
        ? jsonDecode(json['selectedMeats'])
        : json['selectedMeats'];

    // Handle selectedAddons (Map OR String)
    final addonsData = json['selectedAddons'] is String
        ? jsonDecode(json['selectedAddons'])
        : json['selectedAddons'];

    return CartItem(
      menuItem: MenuItem.fromJson(menuItemData),
      quantity: json['quantity'] ?? 1,
      extras: json['extras'] != null ? List<String>.from(json['extras']) : null,
      selectedMeats: meatsData != null
          ? Map<String, int>.from(meatsData)
          : null,
      hasSalad: json['hasSalad'] ?? false,
      selectedAddons: addonsData != null
          ? Map<String, int>.from(addonsData)
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
