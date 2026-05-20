import 'package:flutter_test/flutter_test.dart';
import 'package:campuschow/models/cart_item.dart';
import 'package:campuschow/models/menu_item.dart';
import 'package:campuschow/utils/price_calculator.dart';

void main() {
  group('PriceCalculator Unit Tests', () {
    late MenuItem baseFood;
    late MenuItem chickenMeat;
    late MenuItem beefMeat;
    late MenuItem saladSide;
    late MenuItem fantaDrink;
    late List<MenuItem> menuItemsList;

    setUp(() {
      baseFood = MenuItem(
        id: 'food_jollof',
        storeId: 'store_1',
        name: 'Jollof Rice',
        description: 'Hot smoky jollof',
        price: 1000.0,
        category: 'Rice',
        image: '',
        popular: true,
        isPerPortion: false,
        isFreeWithSwallow: false,
        prepTimeMinutes: 10,
        isReady: true,
        calories: 400,
        addonIds: [],
        sizes: [
          ItemSize(id: 'size_large', name: 'Large', price: 1500.0),
        ],
        extras: [],
      );

      chickenMeat = MenuItem(
        id: 'meat_chicken',
        storeId: 'store_1',
        name: 'Fried Chicken',
        description: 'Crispy fried chicken',
        price: 800.0,
        category: 'Meats',
        image: '',
        popular: false,
        isPerPortion: false,
        isFreeWithSwallow: false,
        prepTimeMinutes: 5,
        isReady: true,
        calories: 250,
        addonIds: [],
        sizes: [],
        extras: [],
      );

      beefMeat = MenuItem(
        id: 'meat_beef',
        storeId: 'store_1',
        name: 'Beef',
        description: 'Chunky beef piece',
        price: 500.0,
        category: 'Meats',
        image: '',
        popular: false,
        isPerPortion: false,
        isFreeWithSwallow: false,
        prepTimeMinutes: 5,
        isReady: true,
        calories: 150,
        addonIds: [],
        sizes: [],
        extras: [],
      );

      saladSide = MenuItem(
        id: 'side_salad',
        storeId: 'store_1',
        name: 'Coleslaw Salad',
        description: 'Fresh salad side',
        price: 300.0,
        category: 'Sides',
        image: '',
        popular: false,
        isPerPortion: false,
        isFreeWithSwallow: false,
        prepTimeMinutes: 5,
        isReady: true,
        calories: 80,
        addonIds: [],
        sizes: [],
        extras: [],
      );

      fantaDrink = MenuItem(
        id: 'drink_fanta',
        storeId: 'store_1',
        name: 'Fanta Orange',
        description: 'Chilled bottle fanta',
        price: 400.0,
        category: 'Drinks',
        image: '',
        popular: false,
        isPerPortion: false,
        isFreeWithSwallow: false,
        prepTimeMinutes: 2,
        isReady: true,
        calories: 120,
        addonIds: [],
        sizes: [],
        extras: [],
      );

      menuItemsList = [baseFood, chickenMeat, beefMeat, saladSide, fantaDrink];
    });

    test('should calculate correct price for base food item', () {
      final cartItem = CartItem(
        menuItem: baseFood,
        quantity: 2,
      );

      final total = PriceCalculator.calculateCartItemPrice(
        cartItem,
        meatPrices: {},
        saladPrice: 0.0,
        allMenuItems: menuItemsList,
      );

      // (1000.0 base) * 2 quantity = 2000.0
      expect(total, equals(2000.0));
    });

    test('should include selected size prices correctly', () {
      final cartItem = CartItem(
        menuItem: baseFood,
        quantity: 1,
        selectedSizeId: 'size_large',
      );

      final total = PriceCalculator.calculateCartItemPrice(
        cartItem,
        meatPrices: {},
        saladPrice: 0.0,
        allMenuItems: menuItemsList,
      );

      // Large size price is 1500.0
      expect(total, equals(1500.0));
    });

    test('should include meat, side, and drink modifier costs correctly', () {
      final cartItem = CartItem(
        menuItem: baseFood,
        quantity: 2,
        selectedMeats: {'meat_chicken': 1, 'meat_beef': 2}, // Chicken (800) + Beef * 2 (1000) = 1800 meat
        selectedSides: {'side_salad': 1}, // Salad (300)
        selectedDrinks: {'drink_fanta': 1}, // Fanta (400)
      );

      final total = PriceCalculator.calculateCartItemPrice(
        cartItem,
        meatPrices: {},
        saladPrice: 0.0,
        allMenuItems: menuItemsList,
      );

      // Base (1000) + Meats (1800) + Side (300) + Drink (400) = 3500 per unit
      // 3500 * 2 quantity = 7000.0
      expect(total, equals(7000.0));
    });

    test('should generate clean customization summary string', () {
      final cartItem = CartItem(
        menuItem: baseFood,
        quantity: 1,
        selectedMeats: {'meat_chicken': 1},
        selectedSides: {'side_salad': 2},
      );

      final summary = PriceCalculator.getCustomizationSummary(
        cartItem,
        allMenuItems: menuItemsList,
      );

      expect(summary, contains('1 x Fried Chicken'));
      expect(summary, contains('2 x Coleslaw Salad'));
    });
  });
}
