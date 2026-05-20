import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:campuschow/models/order.dart';
import 'package:campuschow/services/api_service.dart';
import 'package:campuschow/screens/tabs/order_details_screen.dart';

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

  group('PriceAdjustmentPanel Widget Tests', () {
    late MockAdapter mockAdapter;
    late HttpClientAdapter originalAdapter;

    setUpAll(() {
      const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        return null;
      });
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

    testWidgets('should render price details correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceAdjustmentPanel(
              order: mockOrder,
              onUpdated: () {},
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

    testWidgets('clicking Pay Balance sends ACCEPT request and calls onUpdated', (WidgetTester tester) async {
      var onUpdatedCalled = false;
      var apiCalled = false;

      mockAdapter.handler = (options) async {
        apiCalled = true;
        expect(options.path, contains('/orders/ord_123/price-response'));
        expect(options.method, equals('POST'));
        expect(options.data['action'], equals('ACCEPT'));

        return ResponseBody.fromString(
          jsonEncode({
            'id': 'ord_123',
            'status': 'ACCEPTED',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceAdjustmentPanel(
              order: mockOrder,
              onUpdated: () {
                onUpdatedCalled = true;
              },
            ),
          ),
        ),
      );

      final payButton = find.text('Pay Balance');
      await tester.tap(payButton);
      await tester.pump(); // Start request

      await tester.pumpAndSettle();

      expect(apiCalled, isTrue);
      expect(onUpdatedCalled, isTrue);
      expect(find.text('Price adjustment accepted. Processing order...'), findsOneWidget);
    });

    testWidgets('clicking Cancel Order sends REJECT request and calls onUpdated', (WidgetTester tester) async {
      var onUpdatedCalled = false;
      var apiCalled = false;

      mockAdapter.handler = (options) async {
        apiCalled = true;
        expect(options.path, contains('/orders/ord_123/price-response'));
        expect(options.method, equals('POST'));
        expect(options.data['action'], equals('REJECT'));

        return ResponseBody.fromString(
          jsonEncode({
            'id': 'ord_123',
            'status': 'REJECTED',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceAdjustmentPanel(
              order: mockOrder,
              onUpdated: () {
                onUpdatedCalled = true;
              },
            ),
          ),
        ),
      );

      final cancelButton = find.text('Cancel Order');
      await tester.tap(cancelButton);
      await tester.pump(); // Start request
      await tester.pumpAndSettle();

      expect(apiCalled, isTrue);
      expect(onUpdatedCalled, isTrue);
      expect(find.text('Order cancelled successfully.'), findsOneWidget);
    });
  });
}
