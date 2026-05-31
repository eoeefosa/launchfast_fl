import '../services/api_service.dart';
import '../models/order.dart';

class OrderRepository {
  Future<List<Order>> getOrders() async {
    final response = await apiService.dio.get('/orders');
    if (response.data is! List) {
      throw FormatException(
        'Expected List from /orders, got ${response.data.runtimeType}',
      );
    }
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<Order> placeOrder(Map<String, dynamic> orderData) async {
    final response = await apiService.dio.post('/orders', data: orderData);
    if (response.data is! Map) {
      throw FormatException(
        'Expected Map from /orders, got ${response.data.runtimeType}',
      );
    }
    return Order.fromJson(response.data);
  }

  Future<List<Order>> getMyOrders() async {
    final response = await apiService.dio.get('/orders/my');
    if (response.data is! List) {
      throw FormatException(
        'Expected List from /orders/my, got ${response.data.runtimeType}',
      );
    }
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<Order> updateOrderStatus(String id, String status) async {
    final response = await apiService.dio.patch(
      '/orders/$id/status',
      data: {'status': status},
    );
    if (response.data is! Map) {
      throw FormatException(
        'Expected Map from /orders/$id/status, got ${response.data.runtimeType}',
      );
    }
    return Order.fromJson(response.data);
  }

  Future<Order> updateOrder(String id, Map<String, dynamic> orderData) async {
    final response = await apiService.dio.patch('/orders/$id', data: orderData);
    if (response.data is! Map) {
      throw FormatException(
        'Expected Map from /orders/$id, got ${response.data.runtimeType}',
      );
    }
    return Order.fromJson(response.data);
  }

  Future<List<Order>> getAvailableJobs() async {
    final response = await apiService.dio.get(
      '/orders',
      queryParameters: {'status': 'READY_FOR_PICKUP'},
    );
    if (response.data is! List) {
      throw FormatException(
        'Expected List from /orders (jobs), got ${response.data.runtimeType}',
      );
    }
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<List<Order>> getRiderOrders(String riderId) async {
    final response = await apiService.dio.get(
      '/orders',
      queryParameters: {'riderId': riderId},
    );
    if (response.data is! List) {
      throw FormatException(
        'Expected List from /orders (rider), got ${response.data.runtimeType}',
      );
    }
    return (response.data as List).map((i) => Order.fromJson(i)).toList();
  }

  Future<Order> getOrderById(String id) async {
    final response = await apiService.dio.get('/orders/$id');
    if (response.data is! Map) {
      throw FormatException(
        'Expected Map from /orders/$id, got ${response.data.runtimeType}',
      );
    }
    return Order.fromJson(response.data);
  }

  Future<Map<String, dynamic>> initializePayment(String orderId, String method, {String? email}) async {
    final response = await apiService.dio.post(
      '/payments/initialize',
      data: {
        'orderId': orderId,
        'method': method,
        'email': email,
        'source': 'mobile',
      },
    );
    if (response.data is! Map) {
      throw FormatException(
        'Expected Map from /payments/initialize, got ${response.data.runtimeType}',
      );
    }
    return response.data as Map<String, dynamic>;
  }

  Future<Order> payWithWallet(String orderId) async {
    final response = await apiService.dio.post('/orders/$orderId/pay');
    if (response.data is! Map) {
      throw FormatException(
        'Expected Map from /orders/$orderId/pay, got ${response.data.runtimeType}',
      );
    }
    return Order.fromJson(response.data['order'] ?? response.data);
  }

  Future<Order> respondToPriceAdjustment(String orderId, String action) async {
    // NOTE: backend exposes this as PATCH (consistent with /orders/:id/status
    // and the store-side /orders/:id/adjust-price). Using POST returns 405.
    final response = await apiService.dio.patch(
      '/orders/$orderId/price-response',
      data: {'action': action},
    );
    if (response.data is! Map) {
      throw FormatException(
        'Expected Map from /orders/$orderId/price-response, got ${response.data.runtimeType}',
      );
    }
    return Order.fromJson(response.data);
  }

  Future<Map<String, dynamic>> changeToDelivery(String orderId, String method, {String? email}) async {
    final response = await apiService.dio.post(
      '/orders/$orderId/change-to-delivery',
      data: {
        'method': method,
        'email': email,
      },
    );
    if (response.data is! Map) {
      throw FormatException(
        'Expected Map from /orders/$orderId/change-to-delivery, got ${response.data.runtimeType}',
      );
    }
    return response.data as Map<String, dynamic>;
  }
}
