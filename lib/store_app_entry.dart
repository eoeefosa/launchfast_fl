import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/locator.dart' as store_locator;
import 'package:campuschow/store/lib/main.dart' as store_app;
import 'package:campuschow/store/lib/core/providers/notification_provider.dart' as store_notif;
import 'package:campuschow/store/lib/core/providers/theme_provider.dart' as store_theme;
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart' as store_auth;
import 'package:campuschow/store/lib/features/orders/presentation/cart_provider.dart' as store_cart;
import 'package:campuschow/store/lib/features/orders/presentation/order_provider.dart' as store_order;
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart' as store_store;

bool _locatorInitialized = false;

void launchStoreApp() {
  if (!_locatorInitialized) {
    try {
      store_locator.setupLocator();
      _locatorInitialized = true;
    } catch (e) {
      debugPrint('Store locator already setup or error: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => store_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => store_store.StoreProvider()),
        ChangeNotifierProvider(create: (_) => store_cart.CartProvider()),
        ChangeNotifierProvider(create: (_) => store_order.OrderProvider()),
        ChangeNotifierProvider(create: (_) => store_notif.NotificationProvider()),
        ChangeNotifierProvider(create: (_) => store_theme.ThemeProvider()),
      ],
      child: const store_app.MyApp(),
    ),
  );
}
