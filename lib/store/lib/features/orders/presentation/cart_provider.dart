import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';
import 'package:campuschow/models/store.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoaded = false;
  String? _editingOrderId;
  Map<String, double> _meatPrices = {};
  double _saladPrice = 0;
  List<MenuItem> _allMenuItems = [];
  List<Store> _allStores = [];

  List<CartItem> get items => _items;
  String? get editingOrderId => _editingOrderId;

  void updatePricing({
    required Map<String, double> meatPrices,
    required double saladPrice,
    required List<MenuItem> allMenuItems,
    required List<Store> allStores,
  }) {
    _meatPrices = meatPrices;
    _saladPrice = saladPrice;
    _allMenuItems = allMenuItems;
    _allStores = allStores;
  }

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
        debugPrint('Failed to load cart: $e');
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
    Map<String, int>? selectedSides,
    Map<String, int>? selectedDrinks,
    Map<String, int>? selectedAddons,
  }) {
    // Check if item is from same store
    if (currentStoreId != null && currentStoreId != item.storeId) {
      return false;
    }

    final index = _items.indexWhere(
      (i) =>
          i.menuItem.id == item.id &&
          jsonEncode(i.selectedMeats ?? {}) ==
              jsonEncode(selectedMeats ?? {}) &&
          jsonEncode(i.selectedSides ?? {}) ==
              jsonEncode(selectedSides ?? {}) &&
          jsonEncode(i.selectedDrinks ?? {}) ==
              jsonEncode(selectedDrinks ?? {}) &&
          jsonEncode(i.selectedAddons ?? {}) ==
              jsonEncode(selectedAddons ?? {}),
    );

    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          menuItem: item,
          quantity: quantity,
          extras: extras,
          selectedMeats: selectedMeats,
          selectedSides: selectedSides,
          selectedDrinks: selectedDrinks,
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
    Map<String, int>? selectedSides,
    Map<String, int>? selectedDrinks,
    Map<String, int>? selectedAddons,
  }) {
    _items = [
      CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        menuItem: item,
        quantity: quantity,
        extras: extras,
        selectedMeats: selectedMeats,
        selectedSides: selectedSides,
        selectedDrinks: selectedDrinks,
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
    final index = _items.indexWhere(
      (i) =>
          i.menuItem.id == itemId &&
          (selectedMeats == null ||
              jsonEncode(i.selectedMeats ?? {}) == jsonEncode(selectedMeats)),
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
            id: i.id,
            menuItem: i.menuItem,
            quantity: i.quantity,
            extras: i.extras,
            selectedMeats: i.selectedMeats,
            selectedSides: i.selectedSides,
            selectedDrinks: i.selectedDrinks,
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

  double get subTotal {
    double total = _items.fold(0, (sum, item) {
      double itemPrice = item.menuItem.price;

      // Meat extras
      if (item.selectedMeats != null) {
        item.selectedMeats!.forEach((id, count) {
          final meatItem = _allMenuItems.where((m) => m.id == id).firstOrNull;
          if (meatItem != null) {
            itemPrice += meatItem.price * count;
          } else {
            itemPrice += (_meatPrices[id] ?? 0) * count;
          }
        });
      }

      // Sides extra
      if (item.selectedSides != null) {
        item.selectedSides!.forEach((id, count) {
          final sideItem = _allMenuItems.where((m) => m.id == id).firstOrNull;
          if (sideItem != null) {
            itemPrice += sideItem.price * count;
          } else {
            itemPrice += _saladPrice * count;
          }
        });
      }

      // Drinks extra
      if (item.selectedDrinks != null) {
        item.selectedDrinks!.forEach((id, count) {
          final drinkItem = _allMenuItems.where((m) => m.id == id).firstOrNull;
          if (drinkItem != null) {
            itemPrice += drinkItem.price * count;
          }
        });
      }

      // Addons extras
      if (item.selectedAddons != null) {
        item.selectedAddons!.forEach((addonId, count) {
          final addonItem = _allMenuItems
              .where((m) => m.id == addonId)
              .firstOrNull;
          if (addonItem != null) {
            itemPrice += addonItem.price * count;
          }
        });
      }

      return sum + (itemPrice * item.quantity);
    });

    // Swallow/Soup discount logic
    final swallowCount = _items
        .where((i) => i.menuItem.category == 'Swallow')
        .fold(0, (sum, i) => sum + i.quantity);
    final freeEligibleSoups =
        _items
            .where((i) => i.menuItem.isFreeWithSwallow)
            .expand<double>(
              (i) => List<double>.filled(i.quantity, i.menuItem.price),
            )
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

  double get deliveryFees {
    if (_items.isEmpty) return 0;
    final storeIds = _items.map((i) => i.menuItem.storeId).toSet();
    return storeIds.fold(0.0, (sum, id) {
      final store = _allStores.where((s) => s.id == id).firstOrNull;
      return sum + (store?.deliveryFee ?? 0);
    });
  }

  double get serviceFees {
    if (subTotal == 0) return 0;

    final storeCount = _items.map((i) => i.menuItem.storeId).toSet().length;

    double baseFee;

    if (subTotal < 2000) {
      baseFee = 150;
    } else if (subTotal <= 5000) {
      baseFee = 250;
    } else if (subTotal <= 7000) {
      baseFee = 350;
    } else if (subTotal <= 10000) {
      baseFee = 400;
    } else {
      baseFee = 450;
    }

    final percentageFee = subTotal * 0.025;

    final totalFee = (baseFee * storeCount) + percentageFee;

    return totalFee.clamp(0, 1500);
  }

  double get cartTotal => subTotal + deliveryFees + serviceFees;
}
