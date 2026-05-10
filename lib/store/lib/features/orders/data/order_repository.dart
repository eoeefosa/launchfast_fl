import 'package:campuschow/store/lib/core/network/api_client.dart';
import 'order_model.dart';
import 'package:campuschow/store/lib/features/dashboard/data/store_stats_model.dart';

class OrderRepository {
  Future<List<Order>> getOrders() async {
    final response = await apiService.dio.get('/orders');
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<List<Order>> getStoreOrders(String storeId) async {
    final response = await apiService.dio.get('/orders');
    final List<Order> allOrders = (response.data as List).map((i) => Order.fromJson(i)).toList();
    // In a real app, backend should filter by storeId using a query param like /orders?storeId=xyz
    // For now, doing local filtering to match the old implementation and ensure backward compatibility
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
    } catch (_) {
      // Backend endpoint may not exist yet — return empty stats
      // so the UI degrades gracefully instead of crashing.
      return StoreStats(
        revenue: 0,
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

  Future<Order> updateOrderStatus(String id, String status) async {
    final response = await apiService.dio.patch('/orders/$id/status', data: {'status': status});
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
}

final orderRepository = OrderRepository();
