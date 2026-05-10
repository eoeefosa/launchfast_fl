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
  final String? selectedSizeId;

  /// The soup chosen when this is a swallow item (id, name, effective price).
  final Map<String, dynamic>? selectedSoup;

  CartItem({
    String? id,
    required this.menuItem,
    required this.quantity,
    this.extras,
    this.selectedMeats,
    this.hasSalad = false,
    this.selectedAddons,
    this.selectedSizeId,
    this.selectedSoup,
  }) : id =
           id ??
           '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}';

  // ── Structural equality ─────────────────────────────────────────────────────
  static bool _mapsEqual(Map<String, int>? a, Map<String, int>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  bool sameSlotAs({
    required String menuItemId,
    Map<String, int>? selectedMeats,
    bool hasSalad = false,
    Map<String, int>? selectedAddons,
    String? selectedSizeId,
    String? selectedSoupId,
  }) {
    return menuItem.id == menuItemId &&
        _mapsEqual(this.selectedMeats, selectedMeats) &&
        this.hasSalad == hasSalad &&
        _mapsEqual(this.selectedAddons, selectedAddons) &&
        this.selectedSizeId == selectedSizeId &&
        (selectedSoup?['id'] as String?) == selectedSoupId;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.menuItem.id == menuItem.id &&
        _mapsEqual(other.selectedMeats, selectedMeats) &&
        other.hasSalad == hasSalad &&
        _mapsEqual(other.selectedAddons, selectedAddons) &&
        other.selectedSizeId == selectedSizeId &&
        (other.selectedSoup?['id'] as String?) ==
            (selectedSoup?['id'] as String?);
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
    selectedSizeId,
    selectedSoup?['id'],
  );

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // The backend may return items using several different field names:
    //   - menuItem  : fully populated object (ideal)
    //   - menuItemId: bare reference ID
    //   - foodId    : MongoDB ObjectId string (used in create/list responses)
    //   - food      : fully populated object (some endpoints)
    //   - _id       : Mongo subdocument ID — not the menuItem ID

    final rawItem = json['menuItem'] ?? json['food'];
    final itemId = (json['menuItemId'] ?? json['foodId'] ?? json['food_id'])
        ?.toString();

    MenuItem? menuItem;

    if (rawItem is Map<String, dynamic>) {
      // Fully populated — use directly
      menuItem = MenuItem.fromJson(rawItem);
    } else if (itemId != null) {
      // Bare ID — build a stub so the order can at least be stored/displayed
      menuItem = MenuItem(
        id: itemId,
        storeId: json['storeId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Item',
        description: '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        category: 'Others',
        image: '',
        popular: false,
        isPerPortion: false,
        isFreeWithSwallow: false,
        prepTimeMinutes: 20,
        isReady: true,
        calories: 0,
        addonIds: [],
        sizes: [],
        extras: [],
      );
    }

    if (menuItem == null) {
      // Last resort: log the full JSON shape so we can debug future variants
      throw FormatException(
        'CartItem.fromJson: could not resolve menuItem from keys: ${json.keys.toList()}',
      );
    }

    final meatsData = json['selectedMeats'] as Map<String, dynamic>?;
    final addonsData = json['selectedAddons'] as Map<String, dynamic>?;

    return CartItem(
      id: json['id'],
      menuItem: menuItem,
      quantity: json['quantity'] ?? 1,
      extras: json['extras'] != null ? List<String>.from(json['extras']) : null,
      selectedMeats: meatsData != null
          ? Map<String, int>.from(meatsData)
          : null,
      hasSalad: json['hasSalad'] ?? false,
      selectedAddons: addonsData != null
          ? Map<String, int>.from(addonsData)
          : null,
      selectedSizeId: json['selectedSizeId'],
      selectedSoup: json['selectedSoup'] != null
          ? Map<String, dynamic>.from(json['selectedSoup'] as Map)
          : null,
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
      'selectedSizeId': selectedSizeId,
      if (selectedSoup != null) 'selectedSoup': selectedSoup,
    };
  }
}
