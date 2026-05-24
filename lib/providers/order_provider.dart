import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../locator.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../services/ably_service.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {

  OrderProvider({
    // FIX #13 — injected, not global
    AblyService? ablyService,
    FlutterSecureStorage? storage,
  })  : _ablyService = ablyService ?? locator<AblyService>(),
        _storage = storage ?? const FlutterSecureStorage();

  // ─────────────────────────────────────────────────────────────
  // Dependencies
  // ─────────────────────────────────────────────────────────────

  final AblyService         _ablyService;
  // FIX #11 — FlutterSecureStorage instead of SharedPreferences
  // so order data (addresses, totals) is encrypted at rest.
  final FlutterSecureStorage _storage;

  // ─────────────────────────────────────────────────────────────
  // Storage keys
  // ─────────────────────────────────────────────────────────────

  static const _kOrders = 'launch-fast-orders';

  // ─────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────

  List<Order> _orders  = [];
  bool        _isLoading = false;
  bool        _disposed  = false;
  String?     _error;

  // FIX #16 — track subscribed order IDs to prevent duplicate Ably listeners
  final Set<String> _subscribedOrderIds = {};

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────

  List<Order> get orders    => _orders;
  bool        get isLoading => _isLoading;
  String?     get error     => _error;

  // ─────────────────────────────────────────────────────────────
  // FIX #10 — userId is passed in from AuthProvider, not read from
  // secure storage here. Call initialize() from AuthProvider after
  // login or session restore:
  //
  //   orderProvider.initialize(authProvider.user?.id);
  // ─────────────────────────────────────────────────────────────

  Future<void> initialize(String? userId) async {
    await _loadLocalOrders();

    if (userId != null) {
      if (kDebugMode) debugPrint('[OrderProvider] Subscribing to real-time updates');
      _ablyService.subscribeToUserOrders(userId, _onOrderUpdate);
    } else {
      // Guest session — subscribe to each individually tracked order
      if (kDebugMode) debugPrint('[OrderProvider] Guest session — initialising Ably');
      try {
        await _ablyService.initAblyGuest();
        for (final order in _orders) {
          _subscribeToOrder(order.id);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[OrderProvider] Guest Ably init failed: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Local persistence — encrypted via FlutterSecureStorage
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadLocalOrders() async {
    try {
      final ordersStr = await _storage.read(key: _kOrders);
      if (ordersStr != null) {
        final List<dynamic> list = jsonDecode(ordersStr);
        _orders = list.map((i) => Order.fromJson(i)).toList();
        if (kDebugMode) {
          debugPrint('[OrderProvider] Loaded ${_orders.length} cached order(s)');
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderProvider] _loadLocalOrders error: $e');
    }
  }

  Future<void> _persistOrders() async {
    await _storage.write(
      key: _kOrders,
      value: jsonEncode(_orders.map((o) => o.toJson()).toList()),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FIX #16 — guarded subscribe prevents duplicate Ably listeners
  // ─────────────────────────────────────────────────────────────

  void _subscribeToOrder(String orderId) {
    if (_subscribedOrderIds.contains(orderId)) return;
    _ablyService.subscribeToSingleOrder(orderId, _onOrderUpdate);
    _subscribedOrderIds.add(orderId);
  }

  // ─────────────────────────────────────────────────────────────
  // Real-time handler
  // ─────────────────────────────────────────────────────────────

  void _onOrderUpdate(String orderId, OrderStatus status) {
    if (kDebugMode) {
      debugPrint('[OrderProvider] Ably update — orderId=$orderId, status=${status.name}');
    }
    updateOrderStatus(orderId, status);
    if (status == OrderStatus.priceAdjusted) {
      refreshOrders();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Refresh
  // ─────────────────────────────────────────────────────────────

  Future<void> refreshOrders() async {
    if (kDebugMode) debugPrint('[OrderProvider] refreshOrders: fetching from remote...');
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await locator<OrderRepository>().getMyOrders();
      _error  = null;
      await _persistOrders();
      if (kDebugMode) debugPrint('[OrderProvider] Fetched ${_orders.length} order(s)');
    } catch (e) {
      _error = ApiService.getErrorMessage(e);
      if (kDebugMode) debugPrint('[OrderProvider] refreshOrders error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Place order
  // ─────────────────────────────────────────────────────────────

  Future<Order> placeOrder(Map<String, dynamic> orderData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newOrder = await locator<OrderRepository>().placeOrder(orderData);
      _orders.insert(0, newOrder);
      _error = null;

      // FIX #16 — guarded subscribe; won't duplicate if already tracked
      _subscribeToOrder(newOrder.id);

      await _persistOrders();
      if (kDebugMode) debugPrint('[OrderProvider] Order placed — id=${newOrder.id}');
      return newOrder;
    } catch (e) {
      _error = ApiService.getErrorMessage(e);
      if (kDebugMode) debugPrint('[OrderProvider] placeOrder error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Payment
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> initializePayment(
    String orderId,
    String method, {
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await locator<OrderRepository>().initializePayment(
        orderId,
        method,
        email: email,
      );
      _error = null;
      if (kDebugMode) debugPrint('[OrderProvider] Payment initialised for orderId=$orderId');
      return response;
    } catch (e) {
      _error = ApiService.getErrorMessage(e);
      if (kDebugMode) debugPrint('[OrderProvider] initializePayment error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Update order
  // FIX #15 — return type changed from Future<Order?> to Future<Order>
  //           since every code path either returns an Order or throws.
  // ─────────────────────────────────────────────────────────────

  Future<Order> updateOrder(String id, Map<String, dynamic> orderData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedOrder =
          await locator<OrderRepository>().updateOrder(id, orderData);

      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = updatedOrder;
      } else {
        if (kDebugMode) debugPrint('[OrderProvider] updateOrder: orderId=$id not found locally');
      }

      _error = null;
      await _persistOrders();
      return updatedOrder;
    } catch (e) {
      _error = ApiService.getErrorMessage(e);
      if (kDebugMode) debugPrint('[OrderProvider] updateOrder error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Local status updates
  // ─────────────────────────────────────────────────────────────

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: status);
      notifyListeners();
    } else {
      if (kDebugMode) {
        debugPrint('[OrderProvider] updateOrderStatus: orderId=$orderId not found');
      }
    }
  }

  // FIX #12 — removed the dead firstWhere call whose result was never
  // assigned or used. The copyWith below was always the real update.
  void assignRiderToOrder(String orderId, String riderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status:  OrderStatus.outForDelivery,
        riderId: riderId,
      );
      notifyListeners();
    } else {
      if (kDebugMode) {
        debugPrint('[OrderProvider] assignRiderToOrder: orderId=$orderId not found');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Clear
  // ─────────────────────────────────────────────────────────────

  Future<void> clearOrders() async {
    _orders.clear();
    _subscribedOrderIds.clear();
    await _storage.delete(key: _kOrders);
    if (kDebugMode) debugPrint('[OrderProvider] Orders cleared');
    // Note: Ably is disconnected globally by AuthProvider on logout —
    // do not call ablyService.disconnect() here.
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}