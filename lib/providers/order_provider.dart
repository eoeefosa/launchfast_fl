import 'dart:convert';
import 'package:dio/dio.dart';

import '../locator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../services/ably_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderProvider() {
    debugPrint('[OrderProvider] Initialized — loading local orders...');
    _loadLocalOrders();
  }

  Future<void> _loadLocalOrders() async {
    debugPrint('[OrderProvider] _loadLocalOrders: reading from SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    final ordersStr = prefs.getString('launch-fast-orders');

    if (ordersStr != null) {
      final List<dynamic> ordersList = jsonDecode(ordersStr);
      _orders = ordersList.map((i) => Order.fromJson(i)).toList();
      debugPrint('[OrderProvider] _loadLocalOrders: loaded ${_orders.length} cached order(s).');
      notifyListeners();
    } else {
      debugPrint('[OrderProvider] _loadLocalOrders: no cached orders found.');
    }

    const storage = FlutterSecureStorage();
    final userStr = await storage.read(key: 'launch-fast-user');

    if (userStr != null) {
      debugPrint('[OrderProvider] _loadLocalOrders: user session found, attempting Ably subscription...');
      try {
        final userData = jsonDecode(userStr);
        final userId = userData['id'] as String?;

        if (userId != null) {
          debugPrint('[OrderProvider] _loadLocalOrders: subscribing to real-time updates for userId=$userId');
          locator<AblyService>().subscribeToUserOrders(userId, (orderId, status) {
            debugPrint('[OrderProvider] Ably push received — orderId=$orderId, newStatus=${status.name}');
            updateOrderStatus(orderId, status);
          });
        } else {
          debugPrint('[OrderProvider] _loadLocalOrders: userId is null in stored user data — skipping Ably subscription.');
        }
      } catch (e) {
        debugPrint('[OrderProvider] _loadLocalOrders: error parsing user data or subscribing to Ably — $e');
      }
    } else {
      debugPrint('[OrderProvider] _loadLocalOrders: no user session found — skipping Ably subscription.');
    }
  }

  Future<void> refreshOrders() async {
    debugPrint('[OrderProvider] refreshOrders: fetching from remote...');
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedOrders = await locator<OrderRepository>().getMyOrders();
      _orders = fetchedOrders;
      _error = null;
      debugPrint('[OrderProvider] refreshOrders: fetched ${_orders.length} order(s) successfully.');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'launch-fast-orders',
        jsonEncode(_orders.map((o) => o.toJson()).toList()),
      );
      debugPrint('[OrderProvider] refreshOrders: orders persisted to SharedPreferences.');
    } catch (e) {
      _error = 'Failed to refresh orders. Please try again.';
      debugPrint('[OrderProvider] refreshOrders: ERROR — $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> placeOrder(Map<String, dynamic> orderData) async {
    debugPrint('[OrderProvider] placeOrder: initiating — payload=$orderData');
    _isLoading = true;
    notifyListeners();

    try {
      final newOrder = await locator<OrderRepository>().placeOrder(orderData);
      _orders.insert(0, newOrder);
      _error = null;
      debugPrint('[OrderProvider] placeOrder: success — orderId=${newOrder.id}, total=${newOrder.total}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'launch-fast-orders',
        jsonEncode(_orders.map((o) => o.toJson()).toList()),
      );
      debugPrint('[OrderProvider] placeOrder: updated cache with ${_orders.length} order(s).');
      return newOrder;
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _error = 'Connection timed out. Please try again.';
          debugPrint('[OrderProvider] placeOrder: DioException — TIMEOUT (${e.type})');
        } else {
          final data = e.response?.data;
          if (data is Map) {
            _error = data['message'] ?? data['error'] ?? 'Failed to place order.';
          } else {
            _error = 'Failed to place order. Server returned status ${e.response?.statusCode}.';
          }
          debugPrint('[OrderProvider] placeOrder: DioException — status=${e.response?.statusCode}, body=$data');
        }
      } else {
        _error = 'Failed to place order. Please try again.';
        debugPrint('[OrderProvider] placeOrder: unexpected ERROR — $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> updateOrder(String id, Map<String, dynamic> orderData) async {
    debugPrint('[OrderProvider] updateOrder: orderId=$id — payload=$orderData');
    _isLoading = true;
    notifyListeners();

    try {
      final updatedOrder = await locator<OrderRepository>().updateOrder(id, orderData);
      final index = _orders.indexWhere((o) => o.id == id);

      if (index != -1) {
        _orders[index] = updatedOrder;
        debugPrint('[OrderProvider] updateOrder: order at index=$index replaced successfully.');
      } else {
        debugPrint('[OrderProvider] updateOrder: WARNING — orderId=$id not found in local list; skipping local update.');
      }

      _error = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'launch-fast-orders',
        jsonEncode(_orders.map((o) => o.toJson()).toList()),
      );
      debugPrint('[OrderProvider] updateOrder: cache updated.');
      return updatedOrder;
    } catch (e) {
      _error = 'Failed to update order. Please try again.';
      debugPrint('[OrderProvider] updateOrder: ERROR — $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    debugPrint('[OrderProvider] updateOrderStatus: orderId=$orderId → status=${status.name}');
    final index = _orders.indexWhere((o) => o.id == orderId);

    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: status);
      debugPrint('[OrderProvider] updateOrderStatus: local order updated at index=$index.');
      notifyListeners();
    } else {
      debugPrint('[OrderProvider] updateOrderStatus: WARNING — orderId=$orderId not found in local list.');
    }
  }

  void assignRiderToOrder(String orderId, String riderId) {
    debugPrint('[OrderProvider] assignRiderToOrder: orderId=$orderId, riderId=$riderId');
    final index = _orders.indexWhere((o) => o.id == orderId);

    if (index != -1) {
      _orders.firstWhere((o) => o.id == orderId, orElse: () => Order(
        id: 'EMPTY',
        items: [],
        subtotal: 0,
        serviceFee: 0,
        deliveryFee: 0,
        platformDeliveryProfit: 0,
        walletDeduction: 0,
        total: 0,
        deliveryType: 'pickup',
        status: OrderStatus.cancelled,
        date: '',
        stores: [],
        isPriority: false,
      ));
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.outForDelivery,
        riderId: riderId,
      );
      debugPrint('[OrderProvider] assignRiderToOrder: rider assigned, status set to outForDelivery.');
      notifyListeners();
    } else {
      debugPrint('[OrderProvider] assignRiderToOrder: WARNING — orderId=$orderId not found in local list.');
    }
  }

  Future<void> clearOrders() async {
    debugPrint('[OrderProvider] clearOrders: clearing all orders and disconnecting Ably...');
    _orders = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('launch-fast-orders');
    locator<AblyService>().disconnect();
    debugPrint('[OrderProvider] clearOrders: done — cache cleared, Ably disconnected.');
    notifyListeners();
  }
}