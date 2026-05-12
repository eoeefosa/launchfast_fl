import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:campuschow/firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:campuschow/constants/app_colors.dart';
import 'package:campuschow/locator.dart';
import 'package:campuschow/theme/app_theme.dart';

import 'package:campuschow/providers/auth_provider.dart';
import 'package:campuschow/providers/theme_provider.dart';
import 'package:campuschow/providers/notification_provider.dart';

import 'package:campuschow/providers/store_provider.dart';
import 'package:campuschow/providers/cart_provider.dart';
import 'package:campuschow/providers/order_provider.dart';

import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart'
    as dashboard_store;

import 'package:campuschow/store/lib/features/orders/presentation/order_provider.dart'
    as dashboard_orders;

import 'package:campuschow/store/lib/features/orders/presentation/cart_provider.dart'
    as dashboard_cart;

import 'package:campuschow/store/lib/core/providers/notification_provider.dart'
    as dashboard_notifications;

import 'package:campuschow/store/lib/features/dashboard/presentation/staff_provider.dart'
    as dashboard_staff;

import 'package:campuschow/store/lib/core/services/notification_service.dart';

import 'package:campuschow/router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('=== CampusChow Booting ===');

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    return true;
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  setupLocator();

  final authProvider = AuthProvider();
  await authProvider.initialize();

  final router = createRouter(authProvider);

  await notificationService.init();

  runApp(
    CampusChowApp(
      authProvider: authProvider,
      router: router,
    ),
  );
}

class CampusChowApp extends StatelessWidget {
  final AuthProvider authProvider;
  final RouterConfig<Object> router;

  const CampusChowApp({
    super.key,
    required this.authProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProxyProvider<StoreProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, store, cart) {
            cart ??= CartProvider();
            cart.updatePricing(
              meatPrices: store.meatPrices,
              saladPrice: store.saladPrice,
              allMenuItems: store.menuItems,
              allStores: store.stores,
            );
            return cart;
          },
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_store.StoreProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_orders.OrderProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_cart.CartProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_notifications.NotificationProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_staff.StaffProvider()),
      ],
      child: _AppView(router: router),
    );
  }
}

class _AppView extends StatefulWidget {
  final RouterConfig<Object> router;
  const _AppView({required this.router});

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> with WidgetsBindingObserver {
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncSystemUI();
  }

  @override
  void didChangePlatformBrightness() {
    _syncSystemUI();
  }

  void _syncSystemUI() {
    final brightness = PlatformDispatcher.instance.platformBrightness;
    if (_lastBrightness == brightness) return;
    _lastBrightness = brightness;

    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.darkBackground,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.lightScaffold,
            ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'CampusChow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: widget.router,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 1.0,
                  maxScaleFactor: 1.15,
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}