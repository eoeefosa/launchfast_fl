import 'dart:convert';
import 'package:campuschow/repositories/order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:campuschow/models/order.dart';
import 'package:campuschow/services/api_service.dart';
import 'package:campuschow/screens/tabs/order_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:campuschow/providers/order_provider.dart';
import 'package:campuschow/services/ably_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MockAdapter implements HttpClientAdapter {
  late Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final locator = GetIt.instance;

  group('PriceAdjustmentPanel Widget Tests', () {
    late MockAdapter mockAdapter;
    late HttpClientAdapter originalAdapter;

    setUpAll(() {
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            return null;
          });

      if (!locator.isRegistered<OrderRepository>()) {
        locator.registerSingleton<OrderRepository>(OrderRepository());
      }
      if (!locator.isRegistered<AblyService>()) {
        locator.registerSingleton<AblyService>(MockAblyService());
      }
    });

    setUp(() {
      mockAdapter = MockAdapter();
      originalAdapter = apiService.dio.httpClientAdapter;
      apiService.dio.httpClientAdapter = mockAdapter;
    });

    tearDown(() {
      apiService.dio.httpClientAdapter = originalAdapter;
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
      status: OrderStatus.priceAdjusted,
      deliveryType: 'delivery',
      date: '2026-05-20T00:00:00.000Z',
      isPriority: false,
      stores: [],
    );

    testWidgets('should render price details correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => ChangeNotifierProvider<OrderProvider>(
            create: (_) => OrderProvider(),
            child: MaterialApp(
              home: Scaffold(
                body: PriceAdjustmentPanel(order: mockOrder, onUpdated: () {}),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Price Adjustment Required'), findsOneWidget);
      expect(find.text('Original Total:'), findsOneWidget);
      expect(find.text('₦3000'), findsOneWidget);
      expect(find.text('Updated Total:'), findsOneWidget);
      expect(find.text('₦3800'), findsOneWidget);
      expect(find.text('Balance to Pay:'), findsOneWidget);
      expect(find.text('₦800'), findsOneWidget);
      expect(find.text('Pay Balance'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
    });

    testWidgets(
      'clicking Pay Balance sends ACCEPT request and calls onUpdated',
      (WidgetTester tester) async {
        var onUpdatedCalled = false;
        var apiCalled = false;

        mockAdapter.handler = (options) async {
          if (options.path.contains('/orders/ord_123/price-response')) {
            apiCalled = true;
            expect(options.method, equals('PATCH'));
            expect(options.data['action'], equals('ACCEPT'));

            return ResponseBody.fromString(
              jsonEncode({'id': 'ord_123', 'status': 'ACCEPTED'}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }

          if (options.path.contains('/orders/my')) {
            return ResponseBody.fromString(
              jsonEncode([]),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }

          throw Exception('Unexpected request: ${options.path}');
        };

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => ChangeNotifierProvider<OrderProvider>(
              create: (_) => OrderProvider(),
              child: MaterialApp(
                home: Scaffold(
                  body: PriceAdjustmentPanel(
                    order: mockOrder,
                    onUpdated: () {
                      onUpdatedCalled = true;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final payButton = find.text('Pay Balance');
        await tester.tap(payButton);
        await tester.pump();

        await tester.pumpAndSettle();

        expect(apiCalled, isTrue);
        expect(onUpdatedCalled, isTrue);
        expect(
          find.text('Price adjustment accepted. Processing order...'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'clicking Cancel Order sends REJECT request and calls onUpdated',
      (WidgetTester tester) async {
        var onUpdatedCalled = false;
        var apiCalled = false;

        mockAdapter.handler = (options) async {
          if (options.path.contains('/orders/ord_123/price-response')) {
            apiCalled = true;
            expect(options.method, equals('PATCH'));
            expect(options.data['action'], equals('REJECT'));

            return ResponseBody.fromString(
              jsonEncode({'id': 'ord_123', 'status': 'REJECTED'}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }

          if (options.path.contains('/orders/my')) {
            return ResponseBody.fromString(
              jsonEncode([]),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }

          throw Exception('Unexpected request: ${options.path}');
        };

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => ChangeNotifierProvider<OrderProvider>(
              create: (_) => OrderProvider(),
              child: MaterialApp(
                home: Scaffold(
                  body: PriceAdjustmentPanel(
                    order: mockOrder,
                    onUpdated: () {
                      onUpdatedCalled = true;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final cancelButton = find.text('Cancel Order');
        await tester.tap(cancelButton);
        await tester.pump();

        await tester.pumpAndSettle();

        expect(apiCalled, isTrue);
        expect(onUpdatedCalled, isTrue);
        expect(find.text('Order cancelled successfully.'), findsOneWidget);
      },
    );
  });
}