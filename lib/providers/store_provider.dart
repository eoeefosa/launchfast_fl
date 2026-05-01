import 'dart:async';
import '../locator.dart';
import 'package:flutter/material.dart';
import '../models/store.dart';
import '../models/menu_item.dart';
import '../repositories/menu_repository.dart';
import '../constants/static_data.dart';
import '../services/ably_service.dart';

class StoreProvider with ChangeNotifier {
  List<Store> _stores = StaticData.stores;
  List<MenuItem> _menuItems = StaticData.menuItems;
  bool _isLoading = false;
  String? _error;

  // Stream for UI to show informational dialogs
  final _alertController = StreamController<String>.broadcast();
  Stream<String> get alertStream => _alertController.stream;

  // Pricing config — seeded from StaticData, ready for backend-driven values.
  final Map<String, double> _meatPrices = Map.from(StaticData.meatPrices);
  final double _saladPrice = StaticData.saladPrice;

  List<Store> get stores => _stores;
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, double> get meatPrices => _meatPrices;
  double get saladPrice => _saladPrice;

  StoreProvider() {
    refreshData();
    _setupListeners();
  }

  void _setupListeners() {
    locator<AblyService>().addStoreListener((storeId, isOpen) {
      final index = _stores.indexWhere((s) => s.id == storeId);
      if (index != -1) {
        final oldStatus = _stores[index].isOpen;
        _stores[index] = _stores[index].copyWith(isOpen: isOpen);
        notifyListeners();

        if (oldStatus && !isOpen) {
          _alertController.add('STORE_CLOSED:$storeId');
        }
      }
    });

    locator<AblyService>().addMenuListener((storeId, menuItemId, isReady) {
      if (menuItemId != null && isReady != null) {
        // Specific item update
        final index = _menuItems.indexWhere((m) => m.id == menuItemId);
        if (index != -1) {
          final oldReady = _menuItems[index].isReady;
          _menuItems[index] = MenuItem(
            id: _menuItems[index].id,
            storeId: _menuItems[index].storeId,
            name: _menuItems[index].name,
            description: _menuItems[index].description,
            price: _menuItems[index].price,
            category: _menuItems[index].category,
            image: _menuItems[index].image,
            popular: _menuItems[index].popular,
            isPerPortion: _menuItems[index].isPerPortion,
            isFreeWithSwallow: _menuItems[index].isFreeWithSwallow,
            prepTimeMinutes: _menuItems[index].prepTimeMinutes,
            isReady: isReady,
            calories: _menuItems[index].calories,
            addonIds: _menuItems[index].addonIds,
          );
          notifyListeners();

          if (oldReady && !isReady) {
            _alertController.add('ITEM_UNAVAILABLE:$menuItemId');
          }
        }
      } else {
        // Structural change - reload
        refreshData();
      }
    });
  }

  @override
  void dispose() {
    _alertController.close();
    // locator<AblyService>().removeStoreListener(_onStoreUpdate);
    super.dispose();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fetchedStores = await locator<MenuRepository>().getStores();
      final fetchedMenu = await locator<MenuRepository>().getMenuItems();

      _stores = fetchedStores;
      _menuItems = fetchedMenu;
    } catch (e) {
      _error = 'Failed to fetch data from API';
      // print('Fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMenuItem(Map<String, dynamic> data) async {
    try {
      final newItem = await locator<MenuRepository>().createMenuItem(data);
      _menuItems.add(newItem);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add menu item: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final updated = await locator<MenuRepository>().updateMenuItem(id, data);
      final index = _menuItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _menuItems[index] = updated;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update menu item: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await locator<MenuRepository>().deleteMenuItem(id);
      _menuItems.removeWhere((item) => item.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete menu item: $e';
      notifyListeners();
      rethrow;
    }
  }
}
