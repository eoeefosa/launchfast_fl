import 'dart:async';
import '../locator.dart';
import 'package:flutter/material.dart';
import '../models/store.dart';
import '../models/menu_item.dart';
import '../repositories/menu_repository.dart';
import '../services/ably_service.dart';

class StoreProvider with ChangeNotifier {
  List<Store> _stores = [];
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _error;

  // Stream for UI to show informational dialogs
  final _alertController = StreamController<String>.broadcast();
  Stream<String> get alertStream => _alertController.stream;

  // Pricing config
  Map<String, double> _meatPrices = {};
  double _saladPrice = 0;
  List<String> _halls = [];

  List<Store> get stores => _stores;
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, double> get meatPrices => _meatPrices;
  double get saladPrice => _saladPrice;
  List<String> get halls => _halls;

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
          _menuItems[index] = _menuItems[index].copyWith(isReady: isReady);
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
      final fetchedSettings = await locator<MenuRepository>().getSettings();

      _stores = fetchedStores;
      _menuItems = fetchedMenu;

      // Update platform settings
      if (fetchedSettings['meatPrices'] != null) {
        _meatPrices = Map<String, double>.from(
          (fetchedSettings['meatPrices'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ),
        );
      }
      if (fetchedSettings['saladPrice'] != null) {
        _saladPrice = (fetchedSettings['saladPrice'] as num).toDouble();
      }
      if (fetchedSettings['halls'] != null) {
        _halls = List<String>.from(fetchedSettings['halls'] as List);
      }
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
