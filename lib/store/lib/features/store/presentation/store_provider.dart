import 'dart:async';
import '../../../core/providers/base_provider.dart';
import 'package:campuschow/store/lib/core/constants/static_data.dart';
import '../../../core/services/ably_service.dart';
import 'package:campuschow/store/lib/features/store/data/store_model.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';
import '../data/menu_repository.dart';
import '../data/store_repository.dart';
import 'package:campuschow/store/lib/features/dashboard/data/store_stats_model.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/orders/data/order_repository.dart';

class StoreProvider extends BaseProvider {
  List<Store> _stores = StaticData.stores;
  List<MenuItem> _menuItems = StaticData.menuItems;
  String? _activeStoreId;
  Store? _activeStore;

  // Stream for UI alerts
  final _alertController = StreamController<String>.broadcast();
  Stream<String> get alertStream => _alertController.stream;

  StoreProvider() {
    _initStoreListener();
  }

  List<Store> get stores => _stores;
  List<MenuItem> get menuItems => _menuItems;
  Store? get activeStore => _activeStore;

  void setActiveStore(String storeId) {
    _activeStoreId = storeId;
    _updateCache();
    notifyListeners();
  }

  void _updateCache() {
    if (_activeStoreId != null) {
      try {
        _activeStore = _stores.firstWhere((s) => s.id == _activeStoreId);
      } catch (_) {
        _activeStore = null;
      }
    }
  }

  void _initStoreListener() {
    ablyService.addStoreListener((id, isOpen) {
      final i = _stores.indexWhere((s) => s.id == id);
      if (i != -1) {
        final oldStatus = _stores[i].isOpen;
        _stores[i] = _stores[i].copyWith(isOpen: isOpen);
        if (_stores[i].id == _activeStoreId) _activeStore = _stores[i];
        notifyListeners();

        if (oldStatus && !isOpen) {
          _alertController.add('STORE_CLOSED:$id');
        }
      }
    });

    ablyService.addMenuListener((storeId, menuItemId, isReady) {
      if (menuItemId != null && isReady != null) {
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
        // structural change
        refreshData();
      }
    });
  }

  @override
  void dispose() {
    _alertController.close();
    super.dispose();
  }

  void updateData(List<Store> stores, List<MenuItem> items) {
    _stores = stores;
    _menuItems = items;
    _updateCache();
    notifyListeners();
  }

  Future<void> refreshData() async {
    if (_activeStoreId != null) {
      try {
        final storeResult = await menuRepository.getStores();
        storeResult.fold(
          (stores) {
            _stores = stores;
            try {
              _activeStore = stores.firstWhere((s) => s.id == _activeStoreId);
            } catch (_) {
              // keep old _activeStore if not found in list
            }
          },
          (failure) => setFailure(failure),
        );

        final menuResult = await menuRepository.getMenuItems(_activeStoreId!);
        menuResult.fold(
          (items) => _menuItems = items,
          (failure) => setFailure(failure),
        );
      } catch (e) {
        // unexpected error
      }
      notifyListeners();
    }
  }

  Future<void> addMenuItem(Map<String, dynamic> data) async {
    if (_activeStoreId == null) return;
    setLoading(true);
    (await menuRepository.addMenuItem(_activeStoreId!, data)).fold(
      (newItem) {
        _menuItems.add(MenuItem.fromJson(newItem));
        notifyListeners();
      },
      setFailure,
    );
    setLoading(false);
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    setLoading(true);
    (await menuRepository.updateMenuItem(id, data)).fold(
      (updated) {
        final i = _menuItems.indexWhere((m) => m.id == id);
        if (i != -1) {
          _menuItems[i] = MenuItem.fromJson(updated);
          notifyListeners();
        }
      },
      setFailure,
    );
    setLoading(false);
  }

  Future<void> setOwner(String userId) async {
    setLoading(true);
    final store = await storeRepository.getOwnerStore(userId);
    if (store != null) {
      _activeStoreId = store.id;
      _activeStore = store;
      // Fetch fresh menu items for the store
      await refreshData();
    }
    setLoading(false);
    notifyListeners();
  }

  // Backwards compatibility for dashboard files
  String? get activeStoreId => _activeStoreId;
  String? get ownedStoreId => _activeStoreId;
  Store? get ownedStore => _activeStore;

  void setActiveStoreId(String storeId) {
    setActiveStore(storeId);
  }

  Future<void> updateStore(String storeId, Map<String, dynamic> data) async {
    // Add logic to update a store
    final i = _stores.indexWhere((s) => s.id == storeId);
    if (i != -1) {
      // Dummy update, real app would call repo
      notifyListeners();
    }
  }

  Future<StoreStats> fetchStoreStats() async {
    if (_activeStoreId == null) {
      return StoreStats(revenue: 0, totalOrders: 0, pendingOrders: 0, preparingOrders: 0, topSellingItems: {});
    }
    return await orderRepository.getStoreStats(_activeStoreId!);
  }

  Future<List<Order>> fetchStoreOrders() async {
    if (_activeStoreId == null) return [];
    return await orderRepository.getStoreOrders(_activeStoreId!);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await orderRepository.updateOrderStatus(orderId, status);
    notifyListeners();
  }

  Future<void> toggleStoreStatus(bool value) async {
    if (_activeStore == null) return;
    _activeStore = _activeStore!.copyWith(isOpen: !_activeStore!.isOpen);
    final i = _stores.indexWhere((s) => s.id == _activeStore!.id);
    if (i != -1) _stores[i] = _activeStore!;
    notifyListeners();
  }

  Future<void> deleteMenuItem(String id) async {
    setLoading(true);
    (await menuRepository.deleteMenuItem(id)).fold(
      (success) {
        _menuItems.removeWhere((m) => m.id == id);
        notifyListeners();
      },
      setFailure,
    );
    setLoading(false);
  }
}


