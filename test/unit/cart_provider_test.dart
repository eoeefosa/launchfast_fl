import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuschow/providers/cart_provider.dart';
import 'package:campuschow/models/menu_item.dart';
import 'package:campuschow/models/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartProvider Unit Tests', () {
    late Store mockStore1;
    late Store mockStore2;
    late MenuItem foodStore1;
    late MenuItem otherFoodStore1;
    late MenuItem foodStore2;
    late MenuItem chickenMeat;
    late MenuItem coleslawSide;
    late List<MenuItem> mockMenuItems;
    late List<Store> mockStores;

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      mockStore1 = Store(
        id: 'store_1',
        name: 'Burger Palace',
        tagline: 'Best burgers',
        deliveryTime: '20-30 min',
        rating: 4.5,
        deliveryFee: 500.0,
        priorityFee: 800.0,
        isOpen: true,
        accentColor: Colors.red,
        image: '',
      );

      mockStore2 = Store(
        id: 'store_2',
        name: 'Pizza Hut',
        tagline: 'Hot pizza',
        deliveryTime: '15-25 min',
        rating: 4.2,
        deliveryFee: 600.0,
        priorityFee: 900.0,
        isOpen: true,
        accentColor: Colors.blue,
        image: '',
      );

      foodStore1 = MenuItem(
        id: 'food_1',
        storeId: 'store_1',
        name: 'Cheeseburger',
        description: 'Cheesy hamburger',
        price: 1500.0,
        category: 'Burgers',
        image: '',
      );

      otherFoodStore1 = MenuItem(
        id: 'food_2',
        storeId: 'store_1',
        name: 'French Fries',
        description: 'Crispy fries',
        price: 800.0,
        category: 'Sides',
        image: '',
      );

      foodStore2 = MenuItem(
        id: 'food_3',
        storeId: 'store_2',
        name: 'Pepperoni Pizza',
        description: 'Spicy pepperoni',
        price: 3000.0,
        category: 'Pizza',
        image: '',
      );

      chickenMeat = MenuItem(
        id: 'meat_chicken',
        storeId: 'store_1',
        name: 'Chicken Extra',
        description: '',
        price: 600.0,
        category: 'Meats',
        image: '',
      );

      coleslawSide = MenuItem(
        id: 'side_coleslaw',
        storeId: 'store_1',
        name: 'Coleslaw',
        description: '',
        price: 300.0,
        category: 'Sides',
        image: '',
      );

      mockMenuItems = [foodStore1, otherFoodStore1, foodStore2, chickenMeat, coleslawSide];
      mockStores = [mockStore1, mockStore2];
    });

    test('should start empty and have zero values', () {
      final cart = CartProvider();
      expect(cart.items, isEmpty);
      expect(cart.totalQuantity, equals(0));
      expect(cart.subTotal, equals(0.0));
      expect(cart.deliveryFees, equals(0.0));
      expect(cart.serviceFees, equals(0.0));
      expect(cart.currentStoreId, isNull);
    });

    test('should add items from the same store successfully', () {
      final cart = CartProvider();
      
      final added1 = cart.addToCart(item: foodStore1, quantity: 2);
      expect(added1, isTrue);
      expect(cart.items.length, equals(1));
      expect(cart.totalQuantity, equals(2));
      expect(cart.currentStoreId, equals('store_1'));

      final added2 = cart.addToCart(item: otherFoodStore1, quantity: 1);
      expect(added2, isTrue);
      expect(cart.items.length, equals(2));
      expect(cart.totalQuantity, equals(3));
    });

    test('should prevent adding items from a different store', () {
      final cart = CartProvider();
      
      cart.addToCart(item: foodStore1, quantity: 1);
      
      // Try adding item from store_2
      final added = cart.addToCart(item: foodStore2, quantity: 1);
      expect(added, isFalse);
      expect(cart.items.length, equals(1));
      expect(cart.items[0].menuItem.id, equals('food_1'));
    });

    test('should clear and force add item from another store', () {
      final cart = CartProvider();
      
      cart.addToCart(item: foodStore1, quantity: 2);
      expect(cart.currentStoreId, equals('store_1'));

      cart.forceClearAndAdd(item: foodStore2, quantity: 1);
      expect(cart.items.length, equals(1));
      expect(cart.currentStoreId, equals('store_2'));
      expect(cart.items[0].menuItem.id, equals('food_3'));
      expect(cart.totalQuantity, equals(1));
    });

    test('should update item quantities correctly', () {
      final cart = CartProvider();
      cart.addToCart(item: foodStore1, quantity: 2);

      cart.updateQuantity('food_1', 5);
      expect(cart.items[0].quantity, equals(5));
      expect(cart.totalQuantity, equals(5));

      // Updating to 0 should remove the item
      cart.updateQuantity('food_1', 0);
      expect(cart.items, isEmpty);
      expect(cart.totalQuantity, equals(0));
    });

    test('should update item quantities by ID', () {
      final cart = CartProvider();
      cart.addToCart(item: foodStore1, quantity: 3);
      final cartItemId = cart.items[0].id;

      cart.updateQuantityById(cartItemId, 4);
      expect(cart.items[0].quantity, equals(4));

      cart.updateQuantityById(cartItemId, -1);
      expect(cart.items, isEmpty);
    });

    test('should remove items by ID', () {
      final cart = CartProvider();
      cart.addToCart(item: foodStore1, quantity: 1);
      cart.addToCart(item: otherFoodStore1, quantity: 1);
      expect(cart.items.length, equals(2));

      final firstId = cart.items[0].id;
      cart.removeItemById(firstId);
      expect(cart.items.length, equals(1));
      expect(cart.items[0].menuItem.id, equals('food_2'));
    });

    test('should clear all cart state', () {
      final cart = CartProvider();
      cart.addToCart(item: foodStore1, quantity: 2);
      cart.applyPromoCode('WELCOME10', 10.0, 500.0);
      expect(cart.items.isNotEmpty, isTrue);
      expect(cart.appliedPromoCode, equals('WELCOME10'));

      cart.clearCart();
      expect(cart.items, isEmpty);
      expect(cart.appliedPromoCode, isNull);
      expect(cart.discountPercentage, equals(0.0));
      expect(cart.maxDiscountAmount, equals(0.0));
    });

    group('Pricing and Tiered Service Fees', () {
      test('should calculate subtotal with custom selections correctly', () {
        final cart = CartProvider();
        cart.updatePricing(
          meatPrices: {},
          saladPrice: 0.0,
          allMenuItems: mockMenuItems,
          allStores: mockStores,
        );

        cart.addToCart(
          item: foodStore1,
          quantity: 2,
          selectedMeats: {'meat_chicken': 1}, // + 600
          selectedSides: {'side_law': 1}, // Not in allMenuItems, falls back to saladPrice (0)
        );

        // (1500 base + 600 meat) * 2 = 4200 subtotal
        expect(cart.subTotal, equals(4200.0));
      });

      test('should calculate correct service fees based on tiered subtotal rules', () {
        final cart = CartProvider();
        cart.updatePricing(
          meatPrices: {},
          saladPrice: 0.0,
          allMenuItems: mockMenuItems,
          allStores: mockStores,
        );

        // Tier 1: subTotal < 2000 => 150
        cart.addToCart(item: foodStore1, quantity: 1); // Subtotal = 1500
        expect(cart.subTotal, equals(1500.0));
        expect(cart.serviceFees, equals(150.0));

        // Tier 2: 2000 <= subTotal <= 5000 => 250
        cart.updateQuantity('food_1', 2); // Subtotal = 3000
        expect(cart.subTotal, equals(3000.0));
        expect(cart.serviceFees, equals(250.0));

        // Tier 3: 5000 < subTotal <= 7000 => 350
        cart.updateQuantity('food_1', 4); // Subtotal = 6000
        expect(cart.subTotal, equals(6000.0));
        expect(cart.serviceFees, equals(350.0));

        // Tier 4: 7000 < subTotal <= 10000 => 400
        cart.updateQuantity('food_1', 6); // Subtotal = 9000
        expect(cart.subTotal, equals(9000.0));
        expect(cart.serviceFees, equals(400.0));

        // Tier 5: subTotal > 10000 => 450
        cart.updateQuantity('food_1', 8); // Subtotal = 12000
        expect(cart.subTotal, equals(12000.0));
        expect(cart.serviceFees, equals(450.0));
      });
    });

    group('Promo Code Calculations', () {
      test('should apply percentage discount correctly', () {
        final cart = CartProvider();
        cart.updatePricing(
          meatPrices: {},
          saladPrice: 0.0,
          allMenuItems: mockMenuItems,
          allStores: mockStores,
        );

        cart.addToCart(item: foodStore1, quantity: 2); // Subtotal = 3000
        cart.applyPromoCode('DISCOUNT10', 10.0, 500.0);

        expect(cart.appliedPromoCode, equals('DISCOUNT10'));
        expect(cart.discountAmount, equals(300.0)); // 10% of 3000
      });

      test('should respect the max discount amount limit', () {
        final cart = CartProvider();
        cart.updatePricing(
          meatPrices: {},
          saladPrice: 0.0,
          allMenuItems: mockMenuItems,
          allStores: mockStores,
        );

        cart.addToCart(item: foodStore1, quantity: 6); // Subtotal = 9000
        cart.applyPromoCode('DISCOUNT10', 10.0, 500.0);

        // 10% of 9000 is 900, but max discount is 500
        expect(cart.discountAmount, equals(500.0));
      });

      test('should remove promo code correctly', () {
        final cart = CartProvider();
        cart.addToCart(item: foodStore1, quantity: 2);
        cart.applyPromoCode('DISCOUNT10', 10.0, 500.0);
        expect(cart.discountAmount, equals(300.0));

        cart.removePromoCode();
        expect(cart.appliedPromoCode, isNull);
        expect(cart.discountPercentage, equals(0.0));
        expect(cart.discountAmount, equals(0.0));
      });
    });

    group('Delivery Calculations', () {
      test('should return correct delivery fee and priority charge', () {
        final cart = CartProvider();
        cart.updatePricing(
          meatPrices: {},
          saladPrice: 0.0,
          allMenuItems: mockMenuItems,
          allStores: mockStores,
        );

        cart.addToCart(item: foodStore1, quantity: 2); // Subtotal = 3000 (store_1)
        
        expect(cart.deliveryFees, equals(500.0)); // Delivery fee of store_1
        expect(cart.deliveryChargeFor(DeliveryType.priority), equals(800.0)); // Priority fee of store_1
        expect(cart.deliveryChargeFor(DeliveryType.pickup), equals(0.0)); // Pickup is FREE
      });

      test('should compute totalFor delivery types correctly', () {
        final cart = CartProvider();
        cart.updatePricing(
          meatPrices: {},
          saladPrice: 0.0,
          allMenuItems: mockMenuItems,
          allStores: mockStores,
        );

        cart.addToCart(item: foodStore1, quantity: 2); // Subtotal = 3000
        // Service Fee = 250

        // Pickup Total: 3000 subtotal + 250 service fee + 0 pickup charge = 3250
        expect(cart.totalFor(DeliveryType.pickup), equals(3250.0));

        // Priority Total: 3000 subtotal + 250 service fee + 800 priority charge = 4050
        expect(cart.totalFor(DeliveryType.priority), equals(4050.0));
      });
    });
  });
}
