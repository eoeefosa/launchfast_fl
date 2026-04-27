import 'dart:math';
import 'menu_item.dart';

class CartItem {
  final String id;
  final MenuItem menuItem;
  int quantity;
  final List<String>? extras;
  final Map<String, int>? selectedMeats;
  final bool hasSalad;
  final Map<String, int>? selectedAddons;

  CartItem({
    String? id,
    required this.menuItem,
    required this.quantity,
    this.extras,
    this.selectedMeats,
    this.hasSalad = false,
    this.selectedAddons,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}';

  // ── Structural equality ─────────────────────────────────────────────────────
  // Compares two nullable Map<String,int> maps for value equality without
  // serialising them — eliminates the pathological jsonEncode comparison.
  static bool _mapsEqual(Map<String, int>? a, Map<String, int>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  /// Two CartItems are "the same cart slot" when they share the same menu item,
  /// meat selection, salad flag, and addon selection.
  bool sameSlotAs({
    required String menuItemId,
    Map<String, int>? selectedMeats,
    bool hasSalad = false,
    Map<String, int>? selectedAddons,
  }) {
    return menuItem.id == menuItemId &&
        _mapsEqual(this.selectedMeats, selectedMeats) &&
        this.hasSalad == hasSalad &&
        _mapsEqual(this.selectedAddons, selectedAddons);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.menuItem.id == menuItem.id &&
        _mapsEqual(other.selectedMeats, selectedMeats) &&
        other.hasSalad == hasSalad &&
        _mapsEqual(other.selectedAddons, selectedAddons);
  }

  @override
  int get hashCode => Object.hash(
        menuItem.id,
        Object.hashAllUnordered(
          selectedMeats?.entries.map((e) => Object.hash(e.key, e.value)) ?? [],
        ),
        hasSalad,
        Object.hashAllUnordered(
          selectedAddons?.entries.map((e) => Object.hash(e.key, e.value)) ?? [],
        ),
      );

  // ── Serialisation ───────────────────────────────────────────────────────────

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // The backend sends proper nested JSON objects, not JSON-encoded strings.
    // Guard against both shapes defensively, but the canonical path is Map.
    final rawItem = json['menuItem'];
    if (rawItem == null || rawItem is! Map) {
      throw FormatException('CartItem.fromJson: missing or invalid "menuItem" field');
    }
    final menuItemData = Map<String, dynamic>.from(rawItem);

    final meatsData = json['selectedMeats'] as Map<String, dynamic>?;
    final addonsData = json['selectedAddons'] as Map<String, dynamic>?;

    return CartItem(
      id: json['id'],
      menuItem: MenuItem.fromJson(menuItemData),
      quantity: json['quantity'] ?? 1,
      extras: json['extras'] != null ? List<String>.from(json['extras']) : null,
      selectedMeats:
          meatsData != null ? Map<String, int>.from(meatsData) : null,
      hasSalad: json['hasSalad'] ?? false,
      selectedAddons:
          addonsData != null ? Map<String, int>.from(addonsData) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'extras': extras,
      'selectedMeats': selectedMeats,
      'hasSalad': hasSalad,
      'selectedAddons': selectedAddons,
    };
  }
}
