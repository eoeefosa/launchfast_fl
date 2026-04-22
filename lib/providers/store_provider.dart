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

  List<Store> get stores => _stores;
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StoreProvider() {
    refreshData();
    _initStoreListener();
  }

  void _initStoreListener() {
    ablyService.addStoreListener((storeId, isOpen) {
      final index = _stores.indexWhere((s) => s.id == storeId);
      if (index != -1) {
        _stores[index] = _stores[index].copyWith(isOpen: isOpen);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    // Note: In many Flutter architectures, providers are rarely disposed 
    // unless they are scoped. If you use a scoped provider, you'd want to 
    // remove the listener here.
    // ablyService.removeStoreListener(_onStoreUpdate); 
    super.dispose();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fetchedStores = await menuRepository.getStores();
      final fetchedMenu = await menuRepository.getMenuItems();
      
      if (fetchedStores.isNotEmpty) _stores = fetchedStores;
      if (fetchedMenu.isNotEmpty) _menuItems = fetchedMenu;
    } catch (e) {
      _error = 'Failed to fetch data from API';
      print('Fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMenuItem(Map<String, dynamic> data) async {
    try {
      final newItem = await menuRepository.createMenuItem(data);
      _menuItems.add(newItem);
      notifyListeners();
    } catch (e) {
      print('Add item error: $e');
    }
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final updated = await menuRepository.updateMenuItem(id, data);
      final index = _menuItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _menuItems[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      print('Update item error: $e');
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await menuRepository.deleteMenuItem(id);
      _menuItems.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      print('Delete item error: $e');
    }
  }
}
