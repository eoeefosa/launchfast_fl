import 'package:flutter_test/flutter_test.dart';
import 'package:campuschow/models/cart_item.dart';
import 'package:campuschow/models/menu_item.dart';

void main() {
  group('CartItem Unit Tests', () {
    late MenuItem mockMenuItem;

    setUp(() {
      mockMenuItem = MenuItem(
        id: 'food_123',
        storeId: 'store_123',
        name: 'Spaghetti',
        description: 'Delicious hot pasta',
        price: 1500.0,
        category: 'Swallows',
        image: '',
        popular: true,
        isPerPortion: false,
        isFreeWithSwallow: false,
        prepTimeMinutes: 15,
        isReady: true,
        calories: 350,
        addonIds: [],
        sizes: [],
        extras: [],
      );
    });

    test('should correctly instantiate and serialize to/from JSON', () {
      final cartItem = CartItem(
        menuItem: mockMenuItem,
        quantity: 2,
        selectedMeatsDetails: [
          {'name': 'Chicken', 'price': 800.0, 'quantity': 1, 'id': 'meat_1'}
        ],
        selectedSidesDetails: [
          {'name': 'Coleslaw', 'price': 300.0, 'quantity': 2, 'id': 'side_1'}
        ],
      );

      expect(cartItem.quantity, equals(2));
      expect(cartItem.menuItem.name, equals('Spaghetti'));
      expect(cartItem.selectedMeatsDetails?[0]['name'], equals('Chicken'));
      expect(cartItem.selectedSidesDetails?[0]['price'], equals(300.0));

      final json = cartItem.toJson();
      expect(json['quantity'], equals(2));
      expect(json['selectedMeatsDetails']?[0]['name'], equals('Chicken'));

      final deserialized = CartItem.fromJson(json);
      expect(deserialized.quantity, equals(2));
      expect(deserialized.menuItem.name, equals('Spaghetti'));
      expect(deserialized.selectedMeatsDetails?[0]['name'], equals('Chicken'));
    });

    test('should evaluate sameSlotAs correctly for matching parameters', () {
      final cartItem = CartItem(
        menuItem: mockMenuItem,
        quantity: 1,
        selectedMeats: {'meat_1': 1},
        selectedSides: {'side_1': 1},
      );

      final sameSlot = cartItem.sameSlotAs(
        menuItemId: 'food_123',
        selectedMeats: {'meat_1': 1},
        selectedSides: {'side_1': 1},
      );

      expect(sameSlot, isTrue);

      final differentSlot = cartItem.sameSlotAs(
        menuItemId: 'food_123',
        selectedMeats: {'meat_1': 2}, // different quantity of meat
        selectedSides: {'side_1': 1},
      );

      expect(differentSlot, isFalse);
    });

    test('should fallback gracefully when details arrays are missing', () {
      final json = {
        'menuItemId': 'food_123',
        'name': 'Spaghetti',
        'price': 1500.0,
        'quantity': 3,
      };

      final deserialized = CartItem.fromJson(json);
      expect(deserialized.quantity, equals(3));
      expect(deserialized.menuItem.name, equals('Spaghetti'));
      expect(deserialized.selectedMeatsDetails, isNull);
      expect(deserialized.selectedSidesDetails, isNull);
    });
  });
}
