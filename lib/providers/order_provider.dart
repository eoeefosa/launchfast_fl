import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../services/ably_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderProvider() {
    _loadLocalOrders();
  }

  void initializeAbly(String userId) {
    ablyService.initAbly(userId).then((_) {
      ablyService.subscribeToUserOrders(userId, (orderId, status) {
        updateOrderStatus(orderId, status);
      });
    });
  }

  Future<void> _loadLocalOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersStr = prefs.getString('launch-fast-orders');
    if (ordersStr != null) {
      final List<dynamic> ordersList = jsonDecode(ordersStr);
      _orders = ordersList.map((i) => Order.fromJson(i)).toList();
      notifyListeners();
    }
    
    // Initialize Ably if user is logged in
    const storage = FlutterSecureStorage();
    final userStr = await storage.read(key: 'launch-fast-user');
    if (userStr != null) {
      try {
        final userData = jsonDecode(userStr);
        final userId = userData['id'] as String?;
        if (userId != null) {
          initializeAbly(userId);
        }
      } catch (e) {
        print('Error initializing Ably from stored user: $e');
      }
    }
  }

  Future<void> refreshOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetchedOrders = await orderRepository.getMyOrders();
      _orders = fetchedOrders;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('launch-fast-orders', jsonEncode(_orders.map((o) => o.toJson()).toList()));
      
      const storage = FlutterSecureStorage();
      final userStr = await storage.read(key: 'launch-fast-user');
      if (userStr != null) {
        final userData = jsonDecode(userStr);
        final userId = userData['id'] as String?;
        if (userId != null) initializeAbly(userId);
      }
    } catch (e) {
      print('Failed to refresh orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> placeOrder(Map<String, dynamic> orderData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newOrder = await orderRepository.placeOrder(orderData);
      _orders.insert(0, newOrder);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('launch-fast-orders', jsonEncode(_orders.map((o) => o.toJson()).toList()));
      return newOrder;
    } catch (e) {
      print('Place order error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> updateOrder(String id, Map<String, dynamic> orderData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedOrder = await orderRepository.updateOrder(id, orderData);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('launch-fast-orders', jsonEncode(_orders.map((o) => o.toJson()).toList()));
      return updatedOrder;
    } catch (e) {
      print('Update order error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = Order(
        id: order.id,
        userId: order.userId,
        items: order.items,
        total: order.total,
        status: status,
        date: order.date,
        stores: order.stores,
        isPriority: order.isPriority,
        riderId: order.riderId,
      );
      notifyListeners();
    }
  }

  void assignRiderToOrder(String orderId, String riderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = Order(
        id: order.id,
        userId: order.userId,
        items: order.items,
        total: order.total,
        status: OrderStatus.outForDelivery,
        date: order.date,
        stores: order.stores,
        isPriority: order.isPriority,
        riderId: riderId,
      );
      notifyListeners();
    }
  }

  Future<void> clearOrders() async {
    _orders = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('launch-fast-orders');
    ablyService.disconnect();
    notifyListeners();
  }
}
