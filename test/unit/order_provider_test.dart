import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/services.dart';
import 'package:campuschow/providers/order_provider.dart';
import 'package:campuschow/repositories/order_repository.dart';
import 'package:campuschow/models/order.dart';

class MockOrderRepository implements OrderRepository {
  List<Order> getOrdersResult = [];
  Order? placeOrderResult;
  List<Order> getMyOrdersResult = [];
  Order? updateOrderStatusResult;
  Order? updateOrderResult;
  List<Order> getAvailableJobsResult = [];
  List<Order> getRiderOrdersResult = [];
  Order? getOrderByIdResult;
  Map<String, dynamic> initializePaymentResult = {};
  Order? respondToPriceAdjustmentResult;
  Order? payWithWalletResult;

  Map<String, dynamic>? lastPlaceOrderData;
  String? lastUpdateOrderStatusId;
  String? lastUpdateOrderStatusValue;
  String? lastUpdateOrderId;
  Map<String, dynamic>? lastUpdateOrderData;
  String? lastInitializePaymentOrderId;
  String? lastInitializePaymentMethod;
  String? lastInitializePaymentEmail;
  String? lastPriceAdjustmentOrderId;
  String? lastPriceAdjustmentAction;
  String? lastPayWithWalletOrderId;

  @override
  Future<List<Order>> getOrders() async => getOrdersResult;

  @override
  Future<Order> placeOrder(Map<String, dynamic> orderData) async {
    lastPlaceOrderData = orderData;
    if (placeOrderResult == null) throw Exception('No mock response configured');
    return placeOrderResult!;
  }

  @override
  Future<List<Order>> getMyOrders() async => getMyOrdersResult;

  @override
  Future<Order> updateOrderStatus(String id, String status) async {
    lastUpdateOrderStatusId = id;
    lastUpdateOrderStatusValue = status;
    if (updateOrderStatusResult == null) throw Exception('No mock response configured');
    return updateOrderStatusResult!;
  }

  @override
  Future<Order> updateOrder(String id, Map<String, dynamic> orderData) async {
    lastUpdateOrderId = id;
    lastUpdateOrderData = orderData;
    if (updateOrderResult == null) throw Exception('No mock response configured');
    return updateOrderResult!;
  }

  @override
  Future<List<Order>> getAvailableJobs() async => getAvailableJobsResult;

  @override
  Future<List<Order>> getRiderOrders(String riderId) async => getRiderOrdersResult;

  @override
  Future<Order> getOrderById(String id) async {
    if (getOrderByIdResult == null) throw Exception('No mock response configured');
    return getOrderByIdResult!;
  }

  @override
  Future<Map<String, dynamic>> initializePayment(String orderId, String method, {String? email}) async {
    lastInitializePaymentOrderId = orderId;
    lastInitializePaymentMethod = method;
    lastInitializePaymentEmail = email;
    return initializePaymentResult;
  }

  @override
  Future<Order> respondToPriceAdjustment(String orderId, String action) async {
    lastPriceAdjustmentOrderId = orderId;
    lastPriceAdjustmentAction = action;
    if (respondToPriceAdjustmentResult == null) throw Exception('No mock response configured');
    return respondToPriceAdjustmentResult!;
  }

  @override
  Future<Order> payWithWallet(String orderId) async {
    lastPayWithWalletOrderId = orderId;
    if (payWithWalletResult == null) throw Exception('No mock response configured');
    return payWithWalletResult!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final locator = GetIt.instance;

  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return null;
    });
  });

  group('OrderProvider Unit Tests', () {
    late MockOrderRepository mockRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRepository = MockOrderRepository();

      // Register or override OrderRepository in locator
      if (locator.isRegistered<OrderRepository>()) {
        locator.unregister<OrderRepository>();
      }
      locator.registerSingleton<OrderRepository>(mockRepository);
    });

    final mockOrder = Order(
      id: 'ord_123',
      userId: 'user_789',
      items: [],
      subtotal: 3000.0,
      serviceFee: 250.0,
      deliveryFee: 500.0,
      platformDeliveryProfit: 50.0,
      walletDeduction: 0.0,
      total: 3800.0,
      originalTotal: 3000.0,
      status: OrderStatus.pending,
      deliveryType: 'delivery',
      date: '2026-05-20T00:00:00.000Z',
      isPriority: false,
      stores: [],
    );

    test('should initialize and load orders from cache', () async {
      SharedPreferences.setMockInitialValues({
        'launch-fast-orders': jsonEncode([mockOrder.toJson()]),
      });

      final provider = OrderProvider();
      await Future.delayed(Duration.zero);

      expect(provider.orders.length, equals(1));
      expect(provider.orders.first.id, equals('ord_123'));
    });

    test('refreshOrders fetches and updates orders in cache', () async {
      mockRepository.getMyOrdersResult = [mockOrder];

      final provider = OrderProvider();
      await Future.delayed(Duration.zero);
      expect(provider.orders, isEmpty);

      await provider.refreshOrders();

      expect(provider.orders.length, equals(1));
      expect(provider.orders.first.id, equals('ord_123'));

      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('launch-fast-orders');
      expect(savedStr, isNotNull);
      expect(jsonDecode(savedStr!)[0]['id'], equals('ord_123'));
    });

    test('placeOrder delegates to repository and inserts order in list', () async {
      mockRepository.placeOrderResult = mockOrder;

      final provider = OrderProvider();
      await Future.delayed(Duration.zero);

      final result = await provider.placeOrder({'subtotal': 3000.0});
      expect(result, isNotNull);
      expect(result!.id, equals('ord_123'));
      expect(provider.orders.length, equals(1));
      expect(provider.orders.first.id, equals('ord_123'));
    });

    test('updateOrder updates local order state and cache', () async {
      mockRepository.getMyOrdersResult = [mockOrder];

      final provider = OrderProvider();
      await provider.refreshOrders();
      expect(provider.orders.first.status, equals(OrderStatus.pending));

      final updatedOrder = mockOrder.copyWith(status: OrderStatus.preparing);
      mockRepository.updateOrderResult = updatedOrder;

      await provider.updateOrder('ord_123', {'status': 'preparing'});

      expect(provider.orders.first.status, equals(OrderStatus.preparing));
    });

    test('clearOrders empties provider list and removes cache', () async {
      SharedPreferences.setMockInitialValues({
        'launch-fast-orders': jsonEncode([mockOrder.toJson()]),
      });

      final provider = OrderProvider();
      await Future.delayed(Duration.zero);
      expect(provider.orders.isNotEmpty, isTrue);

      await provider.clearOrders();

      expect(provider.orders, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('launch-fast-orders'), isFalse);
    });
  });
}
