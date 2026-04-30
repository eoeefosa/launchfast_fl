import '../models/store.dart';
import '../models/menu_item.dart';
import '../models/rider.dart';
import 'app_colors.dart';

class StaticData {
  static final List<Store> stores = [
    Store(
      id: 'homeways',
      name: "HomeWays",
      tagline: 'Home-cooked comfort',
      accentColor: AppColors.homeways,
      deliveryTime: '20-35 min',
      rating: 4.9,
      isOpen: true,
      adminUsername: 'homeways',
      deliveryFee: 500,
      image:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=800',
    ),
    Store(
      id: 'rukkies',
      name: 'Rukkies',
      tagline: 'Quick bites, bold flavors',
      accentColor: AppColors.rookies,
      deliveryTime: '10-20 min',
      rating: 4.6,
      isOpen: true,
      adminUsername: 'rookies',
      deliveryFee: 300,
      image:
          'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?auto=format&fit=crop&q=80&w=800',
    ),
  ];

  static final List<Rider> riders = [
    Rider(
      id: 'r1',
      name: 'Buzz Rider - Samuel',
      phoneNumber: '09012345678',
      capacity: 6,
    ),
    Rider(
      id: 'r2',
      name: 'Buzz Rider - Daniel',
      phoneNumber: '08123456789',
      capacity: 6,
    ),
    Rider(
      id: 'r3',
      name: 'Buzz Rider - Victor',
      phoneNumber: '07034567890',
      capacity: 6,
    ),
  ];

  static final List<MenuItem> menuItems = [
    // RICE CATEGORY
    MenuItem(
      id: 'j1',
      storeId: 'homeways',
      name: 'Jollof Rice',
      description: 'Smoky party jollof rice, perfectly spiced.',
      price: 500.00,
      category: 'Rice',
      image:
          'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?auto=format&fit=crop&q=80&w=500',
      popular: true,
      isPerPortion: true,
      isReady: true,
      calories: 450,
      addonIds: ['egg1', 'port1', 'm1'],
    ),
    MenuItem(
      id: 'f1',
      storeId: 'homeways',
      name: 'Fried Rice',
      description:
          'Savory fried rice with vegetables and liver bits. Preparing soon!',
      price: 500.00,
      category: 'Rice',
      image:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&q=80&w=500',
      isPerPortion: true,
      isReady: false,
      prepTimeMinutes: 15,
      calories: 480,
      addonIds: ['egg1', 'port1'],
    ),
    MenuItem(
      id: 'w1',
      storeId: 'homeways',
      name: 'White Rice',
      description: 'Fluffy steamed white rice.',
      price: 400.00,
      category: 'Rice',
      image:
          'https://images.unsplash.com/photo-1516684732162-798a0062be99?auto=format&fit=crop&q=80&w=500',
      isPerPortion: true,
      isReady: true,
      addonIds: ['egg1', 'port1'],
    ),

    // SWALLOW CATEGORY
    MenuItem(
      id: 'py1',
      storeId: 'homeways',
      name: 'Pounded Yam',
      description: 'Smooth and stretchy traditional pounded yam.',
      price: 700.00,
      category: 'Swallow',
      image:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=500',
      popular: true,
      isReady: true,
      calories: 600,
    ),
    MenuItem(
      id: 'ff1',
      storeId: 'homeways',
      name: 'Fufu',
      description: 'Traditional fermented cassava swallow.',
      price: 600.00,
      category: 'Swallow',
      image:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=500',
      isReady: true,
    ),

    // SOUP CATEGORY
    MenuItem(
      id: 'eg1',
      storeId: 'homeways',
      name: 'Egusi Soup',
      description:
          'Rich melon seed soup with assorted meat and fish. Free with swallow!',
      price: 400.00,
      category: 'Soup',
      image:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=500',
      isFreeWithSwallow: true,
      isReady: true,
      calories: 350,
    ),
    MenuItem(
      id: 'og1',
      storeId: 'homeways',
      name: 'Ogbono Soup',
      description:
          'Drawy and delicious wild mango seed soup. Free with swallow!',
      price: 400.00,
      category: 'Soup',
      image:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=500',
      isFreeWithSwallow: true,
      isReady: true,
      calories: 350,
    ),
    MenuItem(
      id: 'gs1',
      storeId: 'homeways',
      name: 'Groundnut Soup',
      description: 'Rich and peanutty traditional soup. Free with swallow!',
      price: 400.00,
      category: 'Soup',
      image:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=500',
      isFreeWithSwallow: true,
      isReady: true,
      calories: 350,
    ),
    MenuItem(
      id: 'vs1',
      storeId: 'homeways',
      name: 'Vegetable Soup',
      description: 'Fresh and nutritious Edikang Ikong or Efo Riro.',
      price: 500.00,
      category: 'Soup',
      image:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=500',
      isReady: true,
      calories: 300,
    ),

    // OTHERS CATEGORY
    MenuItem(
      id: 'h3',
      storeId: 'homeways',
      name: 'Beef Suya Platter',
      description:
          'Grilled spicy beef skewers seasoned with traditional Yaji spice.',
      price: 1000.00,
      category: 'Others',
      image:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=500',
      isReady: true,
      calories: 550,
    ),
    MenuItem(
      id: 'h4',
      storeId: 'homeways',
      name: 'Golden Puff-Puff (12pcs)',
      description: 'A dozen soft, airy, and sweet fried dough balls.',
      price: 500.00,
      category: 'Others',
      image:
          'https://images.unsplash.com/photo-1590080874088-eec64895b423?auto=format&fit=crop&q=80&w=500',
      isReady: true,
      calories: 200,
    ),
    MenuItem(
      id: 'm1',
      storeId: 'homeways',
      name: 'Moi Moi',
      description:
          'Savory steamed bean pudding with egg and fish. Can be enjoyed alone or with rice.',
      price: 800.00,
      category: 'Others',
      image:
          'https://images.unsplash.com/photo-1549590143-d5855148a9d5?auto=format&fit=crop&q=80&w=500',
      isReady: true,
      calories: 400,
    ),
    MenuItem(
      id: 'egg1',
      storeId: 'homeways',
      name: 'Boiled Egg',
      description: 'Perfectly boiled egg, a great protein addition.',
      price: 150.00,
      category: 'Others',
      image:
          'https://images.unsplash.com/photo-1587486913049-53fc88980cfc?auto=format&fit=crop&q=80&w=500',
      isReady: true,
      calories: 70,
    ),
    MenuItem(
      id: 'port1',
      storeId: 'homeways',
      name: 'Extra Portion',
      description: 'Add an extra portion of your main dish.',
      price: 400.00,
      category: 'Others',
      image:
          'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?auto=format&fit=crop&q=80&w=500',
      isReady: true,
    ),

    // Rookies Items
    MenuItem(
      id: 'r1',
      storeId: 'rookies',
      name: 'Fried Yam & Akara',
      description: 'Crispy fried yam sticks served with seasoned bean cakes.',
      price: 800.00,
      category: 'Others',
      image:
          'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&q=80&w=500',
      popular: true,
      isReady: true,
      calories: 500,
    ),
  ];

  static const Map<String, double> meatPrices = {
    'None': 0,
    'Small': 300,
    'Big': 600,
  };

  static const double saladPrice = 200;

  static const List<String> halls = [
    'Hall 1',
    'Hall 2',
    'Hall 3',
    'Hall 4',
    'Hall 5',
    'Hall 6',
    'Hall 7',
    'Hall 8',
    'Faculty',
    'Admin',
  ];
}
