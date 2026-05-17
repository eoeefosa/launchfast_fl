import 'package:flutter/foundation.dart';
import 'package:campuschow/store/lib/core/network/api_client.dart';
import 'order_model.dart';
import 'package:campuschow/store/lib/features/dashboard/data/store_stats_model.dart';

class OrderRepository {
  Future<List<Order>> getOrders() async {
    final response = await apiService.dio.get('/orders');
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<List<Order>> getStoreOrders(String storeId) async {
    final response = await apiService.dio.get('/orders', queryParameters: {
      'storeId': storeId,
      'restaurantId': storeId,
    });
    final List<Order> allOrders = (response.data as List).map((i) => Order.fromJson(i)).toList();
    // Keep local filtering as a safety fallback in case server ignores query params
    return allOrders.where((o) => o.stores.any((s) => s.id == storeId)).toList();
  }

  Future<Order> placeOrder(Map<String, dynamic> orderData) async {
    final response = await apiService.dio.post('/orders', data: orderData);
    return Order.fromJson(response.data);
  }

  Future<StoreStats> getStoreStats(String storeId) async {
    try {
      final response = await apiService.dio.get('/stores/$storeId/stats');
      return StoreStats.fromJson(response.data);
    } catch (e, stack) {
      debugPrint('[OrderRepository] getStoreStats error: $e\n$stack');
      // Backend endpoint may not exist yet — return empty stats
      // so the UI degrades gracefully instead of crashing.
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
  }

  Future<List<Order>> getMyOrders() async {
    final response = await apiService.dio.get('/orders/my');
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<Order> updateOrderStatus(String id, String status, {String? storeId, String? rejectionReason}) async {
    final response = await apiService.dio.patch('/orders/$id/status', data: {
      'status': status,
      if (storeId != null) 'storeId': storeId,
      if (storeId != null) 'restaurantId': storeId,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
    return Order.fromJson(response.data);
  }

  Future<Order> updateOrder(String id, Map<String, dynamic> orderData) async {
    final response = await apiService.dio.patch('/orders/$id', data: orderData);
    return Order.fromJson(response.data);
  }

  Future<List<Order>> getAvailableJobs() async {
    final response = await apiService.dio.get('/orders', queryParameters: {'status': 'READY_FOR_PICKUP'});
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<List<Order>> getRiderOrders(String riderId) async {
    final response = await apiService.dio.get('/orders', queryParameters: {'riderId': riderId});
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<Map<String, dynamic>> getRider(String id) async {
    final response = await apiService.dio.get('/riders/$id');
    return response.data as Map<String, dynamic>;
  }
}

final orderRepository = OrderRepository();
