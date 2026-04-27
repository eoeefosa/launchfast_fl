import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';
import '../constants/static_data.dart';
import '../utils/price_calculator.dart';

// ── Delivery pricing constants ─────────────────────────────────────────────────
// Centralised here so CheckoutScreen only reads state; it never calculates fees.

enum DeliveryType { bulk, priority, pickup }

extension DeliveryTypeX on DeliveryType {
  static DeliveryType fromString(String value) {
    switch (value) {
      case 'priority':
        return DeliveryType.priority;
      case 'pickup':
        return DeliveryType.pickup;
      default:
        return DeliveryType.bulk;
    }
  }

  double get charge {
    switch (this) {
      case DeliveryType.priority:
        return 1300;
      case DeliveryType.pickup:
        return 0;
      case DeliveryType.bulk:
        return 300;
    }
  }

  String get label {
    switch (this) {
      case DeliveryType.priority:
        return 'Priority Delivery';
      case DeliveryType.pickup:
        return 'Pick Up';
      case DeliveryType.bulk:
        return 'Bulk Delivery';
    }
  }

  String get priceLabel {
    switch (this) {
      case DeliveryType.priority:
        return '₦1,300';
      case DeliveryType.pickup:
        return 'FREE';
      case DeliveryType.bulk:
        return '₦300';
    }
  }
}

// ── CartProvider ───────────────────────────────────────────────────────────────

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoaded = false;
  String? _editingOrderId;

  List<CartItem> get items => _items;
  String? get editingOrderId => _editingOrderId;

  String? get currentStoreId =>
      _items.isNotEmpty ? _items[0].menuItem.storeId : null;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartStr = prefs.getString('launch-fast-cart');
    _editingOrderId = prefs.getString('launch-fast-editing-order-id');
    if (cartStr != null) {
      try {
        final List<dynamic> cartList = jsonDecode(cartStr);
        _items = cartList.map((i) => CartItem.fromJson(i)).toList();
      } catch (e) {
        debugPrint('[CartProvider] Failed to load cart: $e');
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveCart() async {
    if (!_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'launch-fast-cart',
      jsonEncode(_items.map((i) => i.toJson()).toList()),
    );
    if (_editingOrderId != null) {
      await prefs.setString('launch-fast-editing-order-id', _editingOrderId!);
    } else {
      await prefs.remove('launch-fast-editing-order-id');
    }
  }

  bool addToCart({
    required MenuItem item,
    required int quantity,
    List<String>? extras,
    Map<String, int>? selectedMeats,
    bool hasSalad = false,
    Map<String, int>? selectedAddons,
  }) {
    if (currentStoreId != null && currentStoreId != item.storeId) {
      return false;
    }

    // Uses CartItem.sameSlotAs() — no jsonEncode, pure map equality.
    final index = _items.indexWhere(
      (i) => i.sameSlotAs(
        menuItemId: item.id,
        selectedMeats: selectedMeats,
        hasSalad: hasSalad,
        selectedAddons: selectedAddons,
      ),
    );

    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          menuItem: item,
          quantity: quantity,
          extras: extras,
          selectedMeats: selectedMeats,
          hasSalad: hasSalad,
          selectedAddons: selectedAddons,
        ),
      );
    }
    _saveCart();
    notifyListeners();
    return true;
  }

  void forceClearAndAdd({
    required MenuItem item,
    required int quantity,
    List<String>? extras,
    Map<String, int>? selectedMeats,
    bool hasSalad = false,
    Map<String, int>? selectedAddons,
  }) {
    _items = [
      CartItem(
        menuItem: item,
        quantity: quantity,
        extras: extras,
        selectedMeats: selectedMeats,
        hasSalad: hasSalad,
        selectedAddons: selectedAddons,
      ),
    ];
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(
    String itemId,
    int newQuantity, {
    Map<String, int>? selectedMeats,
  }) {
    // Uses CartItem._mapsEqual indirectly via sameSlotAs — no jsonEncode.
    final index = _items.indexWhere(
      (i) => i.sameSlotAs(
        menuItemId: itemId,
        selectedMeats: selectedMeats,
      ),
    );

    if (index != -1) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items = [];
    _editingOrderId = null;
    _saveCart();
    notifyListeners();
  }

  void loadOrder(Order order, {bool isEditing = false}) {
    _items = order.items
        .map(
          (i) => CartItem(
            menuItem: i.menuItem,
            quantity: i.quantity,
            extras: i.extras,
            selectedMeats: i.selectedMeats,
            hasSalad: i.hasSalad,
            selectedAddons: i.selectedAddons,
          ),
        )
        .toList();
    _editingOrderId = isEditing ? order.id : null;
    _saveCart();
    notifyListeners();
  }

  void stopEditing() {
    _editingOrderId = null;
    _saveCart();
    notifyListeners();
  }

  // ── Fee calculations (business logic lives here, not in the UI) ─────────────

  /// Computes the item price for a [CartItem] using the given pricing context.
  double itemPrice(
    CartItem item, {
    required Map<String, double> meatPrices,
    required double saladPrice,
    required List<MenuItem> allMenuItems,
  }) {
    return PriceCalculator.calculateCartItemPrice(
      item,
      meatPrices: meatPrices,
      saladPrice: saladPrice,
      allMenuItems: allMenuItems,
    );
  }

  double subTotalWith({
    required Map<String, double> meatPrices,
    required double saladPrice,
    required List<MenuItem> allMenuItems,
  }) {
    double total = _items.fold(
      0,
      (sum, item) => sum + itemPrice(
        item,
        meatPrices: meatPrices,
        saladPrice: saladPrice,
        allMenuItems: allMenuItems,
      ),
    );

    final swallowCount = _items
        .where((i) => i.menuItem.category == 'Swallow')
        .fold(0, (sum, i) => sum + i.quantity);
    final freeEligibleSoups = _items
        .where((i) => i.menuItem.isFreeWithSwallow)
        .expand((i) => List.filled(i.quantity, i.menuItem.price))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final discountCount = swallowCount < freeEligibleSoups.length
        ? swallowCount
        : freeEligibleSoups.length;
    final discount = freeEligibleSoups
        .take(discountCount)
        .fold(0.0, (sum, price) => sum + price);

    return total - discount;
  }

  /// Convenience getter that uses StaticData as fallback.
  /// Widgets that have access to StoreProvider should prefer [subTotalWith].
  double get subTotal => subTotalWith(
    meatPrices: StaticData.meatPrices,
    saladPrice: StaticData.saladPrice,
    allMenuItems: StaticData.menuItems,
  );

  double get deliveryFees {
    if (_items.isEmpty) return 0;
    final storeIds = _items.map((i) => i.menuItem.storeId).toSet();
    return storeIds.fold(0, (sum, id) {
      final store = StaticData.stores.firstWhere((s) => s.id == id);
      return sum + store.deliveryFee;
    });
  }

  double get serviceFees {
    if (subTotal == 0) return 0;
    final storeCount = _items.map((i) => i.menuItem.storeId).toSet().length;
    if (subTotal < 2000) return 100.0 * storeCount;
    if (subTotal <= 5000) return 200.0 * storeCount;
    if (subTotal <= 10000) return 300.0 * storeCount;
    return 350.0 * storeCount;
  }

  /// Delivery charge for the given [DeliveryType]. The UI reads this; it does
  /// not compute it inline.
  double deliveryChargeFor(DeliveryType type) => type.charge;

  double totalFor(DeliveryType deliveryType) =>
      subTotal + serviceFees + deliveryChargeFor(deliveryType);

  double get cartTotal => subTotal + deliveryFees + serviceFees;
}
