import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/services.dart';
import 'package:campuschow/providers/order_provider.dart';
import 'package:campuschow/repositories/order_repository.dart';
import 'package:campuschow/models/order.dart';
import 'package:campuschow/services/ably_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    if (placeOrderResult == null) {
      throw Exception('No mock response configured');
    }
    return placeOrderResult!;
  }

  @override
  Future<List<Order>> getMyOrders() async => getMyOrdersResult;

  @override
  Future<Order> updateOrderStatus(String id, String status) async {
    lastUpdateOrderStatusId = id;
    lastUpdateOrderStatusValue = status;
    if (updateOrderStatusResult == null) {
      throw Exception('No mock response configured');
    }
    return updateOrderStatusResult!;
  }

  @override
  Future<Order> updateOrder(String id, Map<String, dynamic> orderData) async {
    lastUpdateOrderId = id;
    lastUpdateOrderData = orderData;
    if (updateOrderResult == null) {
      throw Exception('No mock response configured');
    }
    return updateOrderResult!;
  }

  @override
  Future<List<Order>> getAvailableJobs() async => getAvailableJobsResult;

  @override
  Future<List<Order>> getRiderOrders(String riderId) async =>
      getRiderOrdersResult;

  @override
  Future<Order> getOrderById(String id) async {
    if (getOrderByIdResult == null) {
      throw Exception('No mock response configured');
    }
    return getOrderByIdResult!;
  }

  @override
  Future<Map<String, dynamic>> initializePayment(
    String orderId,
    String method, {
    String? email,
  }) async {
    lastInitializePaymentOrderId = orderId;
    lastInitializePaymentMethod = method;
    lastInitializePaymentEmail = email;
    return initializePaymentResult;
  }

  @override
  Future<Order> respondToPriceAdjustment(String orderId, String action) async {
    lastPriceAdjustmentOrderId = orderId;
    lastPriceAdjustmentAction = action;
    if (respondToPriceAdjustmentResult == null) {
      throw Exception('No mock response configured');
    }
    return respondToPriceAdjustmentResult!;
  }

  @override
  Future<Order> payWithWallet(String orderId) async {
    lastPayWithWalletOrderId = orderId;
    if (payWithWalletResult == null) {
      throw Exception('No mock response configured');
    }
    return payWithWalletResult!;
  }
  
  @override
  Future<Map<String, dynamic>> changeToDelivery(String orderId, String method, {String? email}) {
    lastInitializePaymentOrderId = orderId;
    lastInitializePaymentMethod = method;
    lastInitializePaymentEmail = email;
    // Return the configured initializePaymentResult to simulate payment/init flow
    return Future.value(initializePaymentResult);
  }
}

class MockAblyService implements AblyService {
  @override
  Future<void> initAbly(String userId) async {}
  @override
  Future<void> initAblyGuest() async {}
  @override
  void subscribeToUserOrders(
    String userId,
    void Function(String orderId, OrderStatus status) onUpdate,
  ) {}
  @override
  void subscribeToSingleOrder(
    String orderId,
    void Function(String orderId, OrderStatus status) onUpdate,
  ) {}
  @override
  void addOrderListener(void Function(String orderId, OrderStatus status) l) {}
  @override
  void removeOrderListener(
    void Function(String orderId, OrderStatus status) l,
  ) {}
  @override
  void addWalletListener(void Function() l) {}
  @override
  void removeWalletListener(void Function() l) {}
  @override
  void notifyWalletUpdate() {}
  @override
  void addMenuListener(
    void Function(String storeId, String? menuItemId, bool? isReady, int? portionsRemaining) l,
  ) {}
  @override
  void removeMenuListener(
    void Function(String storeId, String? menuItemId, bool? isReady, int? portionsRemaining) l,
  ) {}
  @override
  void addStoreListener(void Function(String storeId, bool isOpen) l) {}
  @override
  void removeStoreListener(void Function(String storeId, bool isOpen) l) {}
  @override
  void addRoleListener(void Function(String newRole) l) {}
  @override
  void removeRoleListener(void Function(String newRole) l) {}
  @override
  void addNotificationListener(void Function(Map<String, dynamic> payload) l) {}
  @override
  void removeNotificationListener(
    void Function(Map<String, dynamic> payload) l,
  ) {}
  @override
  void addStoreApprovalListener(void Function(String storeId) l) {}
  @override
  void removeStoreApprovalListener(void Function(String storeId) l) {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> subscribeToRiderChannel(
    String riderId, {
    void Function(Map<String, dynamic> data)? onOrderUpdate,
    void Function(Map<String, dynamic> data)? onNewJob,
  }) async {}
  @override
  void cancelRiderSubscriptions() {}
  @override
  Future<void> subscribeToStoreOrders(String storeId) async {}
  @override
  void removeSubscriptionKey(String key) {}
  @override
  set onPushActivationFailed(
    void Function(Object error)? onPushActivationFailed,
  ) {}
  @override
  void Function(Object error)? get onPushActivationFailed => null;
  @override
 @override
Future<void> publishMenuPriceUpdate({
  required String storeId,
  required String? menuItemId,
  required double price,
}) async {}

  @override
  Future<void> publishPortionUpdate({required String storeId, required String menuItemId, required int portionsRemaining}) {
    // TODO: implement publishPortionUpdate
    throw UnimplementedError();
  }

  @override
  Future<void> publishStoreStatusUpdate({required String storeId, required bool isOpen}) {
    // TODO: implement publishStoreStatusUpdate
    throw UnimplementedError();
  }
  
  @override
  Future<void> publishFeedback({required String storeId, required String orderId, required String feedback, required int rating}) {
    // TODO: implement publishFeedback
    throw UnimplementedError();
  }
}

class MockFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data.containsKey(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final locator = GetIt.instance;

  setUpAll(() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          return null;
        });
  });

  group('OrderProvider Unit Tests', () {
    late MockOrderRepository mockRepository;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRepository = MockOrderRepository();
      mockStorage = MockFlutterSecureStorage();

      // Register or override OrderRepository in locator
      if (locator.isRegistered<OrderRepository>()) {
        locator.unregister<OrderRepository>();
      }
      locator.registerSingleton<OrderRepository>(mockRepository);

      if (locator.isRegistered<AblyService>()) {
        locator.unregister<AblyService>();
      }
      locator.registerSingleton<AblyService>(MockAblyService());
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
      await mockStorage.write(
        key: 'launch-fast-orders',
        value: jsonEncode([mockOrder.toJson()]),
      );

      final provider = OrderProvider(storage: mockStorage);
      await provider.initialize(null);

      expect(provider.orders.length, equals(1));
      expect(provider.orders.first.id, equals('ord_123'));
    });

    test('refreshOrders fetches and updates orders in cache', () async {
      mockRepository.getMyOrdersResult = [mockOrder];

      final provider = OrderProvider(storage: mockStorage);
      await provider.refreshOrders();

      expect(provider.orders.length, equals(1));
      expect(provider.orders.first.id, equals('ord_123'));

      final cached = await mockStorage.read(key: 'launch-fast-orders');
      expect(cached, isNotNull);
    });

    test(
      'placeOrder delegates to repository and inserts order in list',
      () async {
        mockRepository.placeOrderResult = mockOrder;

        final provider = OrderProvider(storage: mockStorage);
        final result = await provider.placeOrder({'subtotal': 3000.0});

        expect(result.id, equals('ord_123'));
        expect(provider.orders.length, equals(1));
        expect(mockRepository.lastPlaceOrderData!['subtotal'], equals(3000.0));
      },
    );

    test('updateOrder updates local order state and cache', () async {
      mockRepository.updateOrderResult = mockOrder.copyWith(
        status: OrderStatus.accepted,
      );
      mockRepository.getMyOrdersResult = [
        mockOrder.copyWith(status: OrderStatus.accepted),
      ];

      final provider = OrderProvider(storage: mockStorage);
      provider.orders.add(mockOrder);

      await provider.updateOrder('ord_123', {'notes': 'No onions'});

      expect(provider.orders.first.status, equals(OrderStatus.accepted));
      expect(mockRepository.lastUpdateOrderId, equals('ord_123'));
    });

    test('clearOrders empties provider list and removes cache', () async {
      await mockStorage.write(
        key: 'launch-fast-orders',
        value: jsonEncode([mockOrder.toJson()]),
      );

      final provider = OrderProvider(storage: mockStorage);
      await provider.initialize(null);
      expect(provider.orders.length, equals(1));

      await provider.clearOrders();

      expect(provider.orders.length, equals(0));
      final cached = await mockStorage.read(key: 'launch-fast-orders');
      expect(cached, isNull);
    });
  });
}
