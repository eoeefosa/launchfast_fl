import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:campuschow/services/api_service.dart';
import 'package:campuschow/repositories/order_repository.dart';
import 'package:campuschow/models/order.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return null;
    });
  });

  group('OrderRepository Unit Tests', () {
    late OrderRepository repository;
    late MockAdapter mockAdapter;
    late HttpClientAdapter originalAdapter;

    setUp(() {
      repository = OrderRepository();
      mockAdapter = MockAdapter();
      originalAdapter = apiService.dio.httpClientAdapter;
      apiService.dio.httpClientAdapter = mockAdapter;
    });

    tearDown(() {
      apiService.dio.httpClientAdapter = originalAdapter;
    });

    final mockOrderJson = {
      'id': 'ord_123',
      'userId': 'user_789',
      'items': [],
      'subtotal': 3000.0,
      'serviceFee': 250.0,
      'deliveryFee': 500.0,
      'platformDeliveryProfit': 50.0,
      'walletDeduction': 0.0,
      'total': 3800.0,
      'originalTotal': 3000.0,
      'status': 'PENDING',
      'deliveryType': 'delivery',
      'createdAt': '2026-05-20T00:00:00.000Z',
      'isPriority': false,
      'stores': [],
    };

    test('getOrders returns list of orders', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders'));
        expect(options.method, equals('GET'));
        return ResponseBody.fromString(
          jsonEncode([mockOrderJson]),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final orders = await repository.getOrders();
      expect(orders, isA<List<Order>>());
      expect(orders.length, equals(1));
      expect(orders.first.id, equals('ord_123'));
    });

    test('placeOrder submits order and returns Order object', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders'));
        expect(options.method, equals('POST'));
        expect(options.data['subtotal'], equals(3000.0));
        return ResponseBody.fromString(
          jsonEncode(mockOrderJson),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final order = await repository.placeOrder({'subtotal': 3000.0});
      expect(order.id, equals('ord_123'));
      expect(order.subtotal, equals(3000.0));
    });

    test('getMyOrders returns list of personal orders', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders/my'));
        expect(options.method, equals('GET'));
        return ResponseBody.fromString(
          jsonEncode([mockOrderJson]),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final orders = await repository.getMyOrders();
      expect(orders.length, equals(1));
      expect(orders.first.userId, equals('user_789'));
    });

    test('updateOrderStatus status update and returns updated Order object', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders/ord_123/status'));
        expect(options.method, equals('PATCH'));
        expect(options.data['status'], equals('ACCEPTED'));
        final updatedJson = Map<String, dynamic>.from(mockOrderJson)..['status'] = 'ACCEPTED';
        return ResponseBody.fromString(
          jsonEncode(updatedJson),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final order = await repository.updateOrderStatus('ord_123', 'ACCEPTED');
      expect(order.status, equals(OrderStatus.accepted));
    });

    test('updateOrder patches general order data and returns updated Order object', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders/ord_123'));
        expect(options.method, equals('PATCH'));
        expect(options.data['notes'], equals('No onions'));
        return ResponseBody.fromString(
          jsonEncode(mockOrderJson),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final order = await repository.updateOrder('ord_123', {'notes': 'No onions'});
      expect(order.id, equals('ord_123'));
    });

    test('getAvailableJobs returns open delivery jobs', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders'));
        expect(options.method, equals('GET'));
        expect(options.queryParameters['status'], equals('READY_FOR_PICKUP'));
        final readyJson = Map<String, dynamic>.from(mockOrderJson)..['status'] = 'READY_FOR_PICKUP';
        return ResponseBody.fromString(
          jsonEncode([readyJson]),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final orders = await repository.getAvailableJobs();
      expect(orders.first.status, equals(OrderStatus.readyForPickup));
    });

    test('getRiderOrders returns orders assigned to rider', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders'));
        expect(options.method, equals('GET'));
        expect(options.queryParameters['riderId'], equals('rider_555'));
        return ResponseBody.fromString(
          jsonEncode([mockOrderJson]),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final orders = await repository.getRiderOrders('rider_555');
      expect(orders.length, equals(1));
    });

    test('getOrderById returns single order details', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders/ord_123'));
        expect(options.method, equals('GET'));
        return ResponseBody.fromString(
          jsonEncode(mockOrderJson),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final order = await repository.getOrderById('ord_123');
      expect(order.id, equals('ord_123'));
    });

    test('initializePayment returns payment details map', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/payments/initialize'));
        expect(options.method, equals('POST'));
        expect(options.data['orderId'], equals('ord_123'));
        expect(options.data['method'], equals('paystack'));
        return ResponseBody.fromString(
          jsonEncode({'authorization_url': 'https://paystack.com/auth'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final res = await repository.initializePayment('ord_123', 'paystack', email: 'user@test.com');
      expect(res['authorization_url'], equals('https://paystack.com/auth'));
    });

    test('respondToPriceAdjustment accepts/rejects price changes', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders/ord_123/price-response'));
        expect(options.method, equals('PATCH'));
        expect(options.data['action'], equals('ACCEPT'));
        final acceptedJson = Map<String, dynamic>.from(mockOrderJson)..['status'] = 'ACCEPTED';
        return ResponseBody.fromString(
          jsonEncode(acceptedJson),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final order = await repository.respondToPriceAdjustment('ord_123', 'ACCEPT');
      expect(order.status, equals(OrderStatus.accepted));
    });

    test('payWithWallet makes post request and returns updated order', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, equals('/orders/ord_123/pay'));
        expect(options.method, equals('POST'));
        final paidJson = Map<String, dynamic>.from(mockOrderJson)..['status'] = 'PLACED';
        return ResponseBody.fromString(
          jsonEncode({'order': paidJson}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final order = await repository.payWithWallet('ord_123');
      expect(order.status, equals(OrderStatus.pending));
    });
  });
}
