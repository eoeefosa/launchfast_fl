import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/error/failures.dart';
import '../../../core/services/ably_service.dart';
import 'package:campuschow/store/lib/features/store/data/store_model.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';
import '../data/menu_repository.dart';
import '../data/store_repository.dart';
import 'package:campuschow/store/lib/features/dashboard/data/store_stats_model.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/orders/data/order_repository.dart';

class StoreProvider extends BaseProvider {
  List<Store> _stores = [];
  List<MenuItem> _menuItems = [];
  final Set<String> _updatingMenuItemIds = {};
  String? _activeStoreId;
  Store? _activeStore;
  Map<String, double> _meatPrices = {};
  double _saladPrice = 0;
  final Map<String, dynamic> _riders = {};

  // Stream for UI alerts
  final _alertController = StreamController<String>.broadcast();
  Stream<String> get alertStream => _alertController.stream;

  StoreProvider() {
    _initStoreListener();
  }

  List<Store> get stores => _stores;
  List<MenuItem> get menuItems => _menuItems;
  Store? get activeStore => _activeStore;
  Map<String, double> get meatPrices => _meatPrices;
  double get saladPrice => _saladPrice;
  bool isMenuItemUpdating(String id) => _updatingMenuItemIds.contains(id);

  List<MenuItem> get meatItems => _menuItems
      .where((m) => m.storeId == _activeStoreId && m.type == 'protein')
      .toList();

  List<MenuItem> get saladItems => _menuItems
      .where((m) => m.storeId == _activeStoreId && m.type == 'side')
      .toList();

  Future<dynamic> getRider(String id) async {
    if (_riders.containsKey(id)) return _riders[id];
    try {
      final rider = await orderRepository.getRider(id);
      _riders[id] = rider;
      return rider;
    } catch (e) {
      debugPrint('Error fetching rider $id: $e');
      return null;
    }
  }

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
        bool updatedAny = false;
        for (int i = 0; i < _menuItems.length; i++) {
          if (_menuItems[i].id == menuItemId ||
              _menuItems[i].id == '${menuItemId}_turkey') {
            final oldReady = _menuItems[i].isReady;
            _menuItems[i] = _menuItems[i].copyWith(isReady: isReady);
            updatedAny = true;
            if (oldReady && !isReady) {
              _alertController.add('ITEM_UNAVAILABLE:${_menuItems[i].id}');
            }
          }
        }
        if (updatedAny) {
          notifyListeners();
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
    final List<MenuItem> processed = [];
    for (final item in items) {
      if (item.name.toUpperCase() == 'CHICKEN & TURKEY') {
        processed.add(item.copyWith(name: 'CHICKEN'));
        processed.add(item.copyWith(id: '${item.id}_turkey', name: 'TURKEY'));
      } else {
        processed.add(item);
      }
    }
    _menuItems = processed;
    _updateCache();
    notifyListeners();
  }

  Future<void> refreshData() async {
    _riders.clear();
    final storeId = _activeStoreId;
    if (storeId != null) {
      try {
        // Fetch fresh menu items for the store
        final menuResult = await menuRepository.getMenuItems(storeId);
        menuResult.fold((items) {
          final List<MenuItem> processed = [];
          for (final item in items) {
            if (item.name.toUpperCase() == 'CHICKEN & TURKEY') {
              processed.add(item.copyWith(name: 'CHICKEN'));
              processed.add(
                item.copyWith(id: '${item.id}_turkey', name: 'TURKEY'),
              );
            } else {
              processed.add(item);
            }
          }
          _menuItems = processed;
          debugPrint('[StoreProvider] Fetched ${items.length} menu items');
        }, (failure) => setFailure(failure));

        // Fetch platform settings (pricing, etc.)
        final settingsResult = await menuRepository.getSettings();
        settingsResult.fold((settings) {
          if (settings['meatPrices'] != null) {
            _meatPrices = Map<String, double>.from(
              (settings['meatPrices'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            );
          }
          if (settings['saladPrice'] != null) {
            _saladPrice = (settings['saladPrice'] as num).toDouble();
          }
        }, (failure) => debugPrint('Failed to fetch settings: $failure'));
      } catch (e) {
        debugPrint('Error in refreshData: $e');
      }
      notifyListeners();
    }
  }

  Future<void> addMenuItem(Map<String, dynamic> data) async {
    if (_activeStoreId == null) return;
    setLoading(true);
    (await menuRepository.addMenuItem(_activeStoreId!, data)).fold((newItem) {
      _menuItems.add(MenuItem.fromJson(newItem));
      notifyListeners();
    }, setFailure);
    setLoading(false);
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    _updatingMenuItemIds.add(id);
    notifyListeners();

    try {
      (await menuRepository.updateMenuItem(id, data)).fold((updated) {
        final i = _menuItems.indexWhere((m) => m.id == id);
        if (i != -1) {
          _menuItems[i] = MenuItem.fromJson(updated);
          notifyListeners();
        }
      }, setFailure);
    } finally {
      _updatingMenuItemIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> setOwner(String userId, {String? linkedStoreId}) async {
    setLoading(true);

    Store? store;

    // 1. Try fetching by the linked restaurantId/adminStore if provided
    if (linkedStoreId != null && linkedStoreId.isNotEmpty) {
      debugPrint('[StoreProvider] Fetching linked store by ID: $linkedStoreId');
      store = await storeRepository.getStore(linkedStoreId);
    }

    // 2. Fallback to searching by ownerId if not found or no link
    if (store == null) {
      debugPrint('[StoreProvider] Searching for store by ownerId: $userId');
      store = await storeRepository.getOwnerStore(userId);
    }

    debugPrint('''
[StoreProvider] Setting Owner Result:
  User ID: $userId
  Store Found: ${store != null}
  Store ID: ${store?.id}
  Store Name: ${store?.name}
  Is Approved: ${store?.isApproved}
''');

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

  Future<Store?> reloadStore(String storeId) async {
    try {
      final updatedStore = await storeRepository.getStore(storeId);
      if (updatedStore == null) return null;

      final index = _stores.indexWhere((store) => store.id == storeId);
      if (index != -1) {
        _stores[index] = updatedStore;
      } else {
        _stores.add(updatedStore);
      }

      if (_activeStoreId == storeId) {
        _activeStore = updatedStore;
      }

      notifyListeners();
      return updatedStore;
    } catch (e) {
      setFailure(ServerFailure(e.toString()));
      rethrow;
    }
  }

  Future<void> updateStore(String storeId, Map<String, dynamic> data) async {
    setLoading(true);
    try {
      final updatedStore = await storeRepository.updateStore(storeId, data);
      final i = _stores.indexWhere((s) => s.id == storeId);
      if (i != -1) {
        _stores[i] = updatedStore;
      }
      if (_activeStoreId == storeId) {
        _activeStore = updatedStore;
      }
      notifyListeners();
    } catch (e) {
      setFailure(ServerFailure(e.toString()));
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<StoreStats> fetchStoreStats() async {
    debugPrint(
      '[StoreProvider] fetchStoreStats called with _activeStoreId: $_activeStoreId',
    );
    if (_activeStoreId == null) {
      return StoreStats(
        revenue: 0,
        foodRevenue: 0,
        deliveryRevenue: 0,
        totalOrders: 0,
        pendingOrders: 0,
        preparingOrders: 0,
        topSellingItems: {},
      );
    }
    return await orderRepository.getStoreStats(_activeStoreId!);
  }

  Future<List<Order>> fetchStoreOrders() async {
    if (_activeStoreId == null) return [];
    return await orderRepository.getStoreOrders(_activeStoreId!);
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
  }) async {
    if (_activeStoreId == null) return;
    await orderRepository.updateOrderStatus(
      orderId,
      status,
      storeId: _activeStoreId!,
      rejectionReason: rejectionReason,
    );
    notifyListeners();
  }

  Future<void> adjustOrderPrice(
    String orderId,
    List<Map<String, dynamic>> items,
  ) async {
    if (_activeStoreId == null) return;
    await orderRepository.adjustOrderPrice(
      orderId,
      items,
      storeId: _activeStoreId!,
    );
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
    (await menuRepository.deleteMenuItem(id)).fold((success) {
      _menuItems.removeWhere((m) => m.id == id);
      notifyListeners();
    }, setFailure);
    setLoading(false);
  }
}
