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

class StoreAppWrapper extends StatefulWidget {
  const StoreAppWrapper({super.key});

  @override
  State<StoreAppWrapper> createState() => _StoreAppWrapperState();
}

class _StoreAppWrapperState extends State<StoreAppWrapper> {
  @override
  void initState() {
    super.initState();
    if (!_locatorInitialized) {
      try {
        store_locator.setupLocator();
        _locatorInitialized = true;
      } catch (e) {
        debugPrint('Store locator already setup or error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => store_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => store_store.StoreProvider()),
        ChangeNotifierProvider(create: (_) => store_cart.CartProvider()),
        ChangeNotifierProvider(create: (_) => store_order.OrderProvider()),
        ChangeNotifierProvider(create: (_) => store_notif.NotificationProvider()),
        ChangeNotifierProvider(create: (_) => store_theme.ThemeProvider()),
      ],
      child: const store_app.MyApp(),
    );
  }
}

// Keep launchStoreApp as a fallback wrapper around runApp for imperative use if needed.
void launchStoreApp() {
  runApp(const StoreAppWrapper());
}
