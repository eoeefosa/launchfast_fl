import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:campuschow/providers/payment_provider.dart';

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
import 'package:campuschow/services/ably_service.dart';

import 'package:campuschow/router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('=== CampusChow Booting ===');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

    if (!authProvider.isAuthenticated) {
      debugPrint('[Main] User unauthenticated, initializing guest Ably...');
      ablyService.initAblyGuest().catchError((e) {
        debugPrint('[Main] Guest Ably init failed: $e');
      });
    }

    final router = createRouter(authProvider);

    await notificationService.init();

    runApp(
      CampusChowApp(
        authProvider: authProvider,
        router: router,
      ),
    );
  } catch (e, stack) {
    debugPrint('=== CRITICAL STARTUP ERROR ===');
    debugPrint(e.toString());
    debugPrint(stack.toString());
    
    runApp(StartupErrorApp(error: e.toString()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final String error;
  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The app could not start correctly. This is often due to missing configuration or network issues.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart or just show info
                  },
                  child: const Text('Check for Updates'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
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
            if (child == null) return const SizedBox.shrink();
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 1.0,
                  maxScaleFactor: 1.15,
                ),
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}