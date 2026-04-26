import '../services/api_service.dart';
import '../models/order.dart';

class OrderRepository {
  Future<List<Order>> getOrders() async {
    final response = await apiService.dio.get('/orders');
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<Order> placeOrder(Map<String, dynamic> orderData) async {
    final response = await apiService.dio.post('/orders', data: orderData);
    return Order.fromJson(response.data);
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
