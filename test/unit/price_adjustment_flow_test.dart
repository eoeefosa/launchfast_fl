import 'package:flutter_test/flutter_test.dart';
import 'package:campuschow/models/order.dart';

void main() {
  group('Price Adjustment Model Unit Tests', () {
    test('should parse Order status PRICE_ADJUSTED and originalTotal correctly from JSON', () {
      final json = {
        'id': 'ord_123',
        'userId': 'user_789',
        'items': [],
        'subtotal': 3000.0,
        'serviceFee': 250.0,
        'deliveryFee': 550.0,
        'platformDeliveryProfit': 50.0,
        'walletDeduction': 0.0,
        'total': 3800.0,
        'originalTotal': 3000.0,
        'status': 'PRICE_ADJUSTED',
        'deliveryType': 'delivery',
        'createdAt': '2026-05-20T00:00:00.000Z',
        'isPriority': false,
        'stores': [],
      };

      final order = Order.fromJson(json);

      expect(order.status, equals(OrderStatus.priceAdjusted));
      expect(order.originalTotal, equals(3000.0));
      expect(order.total, equals(3800.0));
    });

    test('should serialize Order with priceAdjusted status and originalTotal to JSON', () {
      final order = Order(
        id: 'ord_123',
        userId: 'user_789',
        items: [],
        subtotal: 3000.0,
        serviceFee: 250.0,
        deliveryFee: 550.0,
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

      final json = order.toJson();

      expect(json['status'], equals('priceAdjusted'));
      expect(json['originalTotal'], equals(3000.0));
      expect(json['total'], equals(3800.0));
    });
  });
}
