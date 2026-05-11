import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:campuschow/firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:campuschow/constants/app_colors.dart';
import 'package:campuschow/locator.dart';

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

// ─────────────────────────────────────────────────────────────────────────────
// Global navigator key
// ─────────────────────────────────────────────────────────────────────────────

final rootNavigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('=== CampusChow Booting ===');

  // Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);

    debugPrint('[FlutterError]');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
  };

  // Async/platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    debugPrint(stack.toString());

    return true;
  };

  // Portrait lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dependency injection
  setupLocator();

  // Create auth provider BEFORE app
  final authProvider = AuthProvider();

  // Wait for auth bootstrap
  await authProvider.initialize();

  // Router should exist ONCE
  final router = createRouter(authProvider);

  // Notifications AFTER router exists
  await notificationService.init();

  runApp(
    CampusChowApp(
      authProvider: authProvider,
      router: router,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────────────────────

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

    debugPrint('[CampusChowApp] build');

    return MultiProvider(
      providers: [

        // ─────────────────────────────────────────────────────────────
        // Core providers
        // ─────────────────────────────────────────────────────────────

        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),

        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),

        // ─────────────────────────────────────────────────────────────
        // Customer providers
        // ─────────────────────────────────────────────────────────────

        ChangeNotifierProvider(
          create: (_) => StoreProvider(),
        ),

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

        ChangeNotifierProvider(
          create: (_) => OrderProvider(),
        ),

        // ─────────────────────────────────────────────────────────────
        // Dashboard providers
        // ─────────────────────────────────────────────────────────────

        ChangeNotifierProvider(
          create: (_) => dashboard_store.StoreProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => dashboard_orders.OrderProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => dashboard_cart.CartProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => dashboard_notifications.NotificationProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => dashboard_staff.StaffProvider(),
        ),
      ],

      child: _AppView(router: router),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App View
// ─────────────────────────────────────────────────────────────────────────────

class _AppView extends StatefulWidget {
  final RouterConfig<Object> router;

  const _AppView({
    required this.router,
  });

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView>
    with WidgetsBindingObserver {

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

    final brightness =
        PlatformDispatcher.instance.platformBrightness;

    if (_lastBrightness == brightness) {
      return;
    }

    _lastBrightness = brightness;

    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.darkScaffold,
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

  static TextTheme _textTheme([
    Brightness brightness = Brightness.light,
  ]) {
    return GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );
  }

  late final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
      surface: Colors.white,
    ),

    textTheme: _textTheme(),

    scaffoldBackgroundColor: AppColors.lightScaffold,
  );

  late final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF1C1C1E),
    ),

    textTheme: _textTheme(Brightness.dark),

    scaffoldBackgroundColor: AppColors.darkScaffold,
  );

  @override
  Widget build(BuildContext context) {

    final themeProvider =
        context.watch<ThemeProvider>();

    return ScreenUtilInit(
      designSize: const Size(393, 852),

      minTextAdapt: true,

      splitScreenMode: true,

      builder: (context, child) {

        return MaterialApp.router(

          title: 'CampusChow',

          debugShowCheckedModeBanner: false,

          theme: _lightTheme,

          darkTheme: _darkTheme,

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