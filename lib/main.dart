import 'dart:ui';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:campuschow/services/network_service.dart';
import 'package:campuschow/widgets/common/network_status_overlay.dart';

import 'package:campuschow/firebase_options.dart';
import 'package:campuschow/locator.dart';
import 'package:campuschow/router.dart';
import 'package:campuschow/theme/app_theme.dart';

import 'package:campuschow/providers/auth_provider.dart';
import 'package:campuschow/providers/cart_provider.dart';
import 'package:campuschow/providers/notification_provider.dart';
import 'package:campuschow/providers/order_provider.dart';
import 'package:campuschow/providers/payment_provider.dart';
import 'package:campuschow/providers/rider_job_provider.dart';
import 'package:campuschow/providers/store_provider.dart';
import 'package:campuschow/providers/theme_provider.dart';
import 'package:campuschow/services/ably_service.dart';

import 'package:campuschow/store/pages/core/providers/notification_provider.dart'
    as dashboard_notifications;
import 'package:campuschow/store/pages/core/services/notification_service.dart';
import 'package:campuschow/store/pages/features/dashboard/presentation/staff_provider.dart'
    as dashboard_staff;
import 'package:campuschow/store/pages/features/orders/presentation/cart_provider.dart'
    as dashboard_cart;
import 'package:campuschow/store/pages/features/orders/presentation/order_provider.dart'
    as dashboard_orders;
import 'package:campuschow/store/pages/features/store/presentation/store_provider.dart'
    as dashboard_store;

// ─────────────────────────────────────────────────────────────────────────────
// Globals — only what truly must be global
// ─────────────────────────────────────────────────────────────────────────────

/// Root navigator key is now defined in router.dart

/// Runs in a separate Dart isolate; keep it lean.
/// Firebase must be re-initialised here because it is a fresh isolate.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  try {
    developer.log(
      'Received background message: id=${message.messageId} notification=${message.notification != null} data=${message.data}',
      name: 'FCM-BG',
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FCM already displayed a notification for messages that carry a
    // `notification` payload — avoid showing a duplicate.
    if (message.notification != null) {
      developer.log(
        'Message contains notification payload, skipping custom local notification.',
        name: 'FCM-BG',
      );
      return;
    }
    if (message.data.isEmpty) {
      developer.log('Message data is empty, skipping.', name: 'FCM-BG');
      return;
    }

    final (title, body) = _resolveNotificationCopy(message.data);
    developer.log('Resolved copy: title=$title, body=$body', name: 'FCM-BG');

    if (title == null || body == null) {
      developer.log(
        'Could not resolve title or body for custom notification.',
        name: 'FCM-BG',
      );
      return;
    }

    final orderId = message.data['orderId'] ?? message.data['id'];
    final type = message.data['type']?.toString();
    final payload = type == 'new_order' && orderId != null
        ? 'store_order_$orderId'
        : orderId?.toString();

    developer.log(
      'Showing local notification for order: $orderId',
      name: 'FCM-BG',
    );
    await NotificationService.showStaticNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
    );
    developer.log('Local notification displayed successfully.', name: 'FCM-BG');
  } catch (e, stack) {
    developer.log(
      'Error processing background message',
      name: 'FCM-BG',
      error: e,
      stackTrace: stack,
    );
  }
}

/// Maps raw FCM data to a human-readable (title, body) pair.
/// Returns `(null, null)` when the [type] is unrecognised.
(String?, String?) _resolveNotificationCopy(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  final orderId = data['orderId'] ?? data['id'];
  final status = (data['status'] as String?)?.toLowerCase() ?? '';
  final amount = data['amount'] as String?;

  return switch (type) {
    'payment_success' || 'payment_alert' => (
      'Payment Successful',
      'Your payment for order #$orderId was confirmed.',
    ),
    'order_update' => (
      'Order Updated',
      status.isNotEmpty
          ? 'Your order status is now: ${status.replaceAll('_', ' ')}'
          : 'Your order has been updated.',
    ),
    'order_processing' => (
      'Order Processing',
      status.isNotEmpty
          ? 'Your order status is now: ${status.replaceAll('_', ' ')}'
          : 'Your order is being processed.',
    ),
    'price_adjusted' || 'priceadjusted' || 'price_adjustment' => (
      'Order Price Updated',
      'The store owner updated your order price. Tap to review.',
    ),
    'deposit' => (
      'Deposit Successful',
      amount != null
          ? '₦$amount has been added to your wallet.'
          : 'Your wallet has been topped up successfully.',
    ),
    'new_order' => (
      'New Order Received!',
      'A customer just placed a new order.',
    ),
    _ => (null, null),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NetworkService().startMonitoring();

  try {
    debugPrint('=== CampusChow Booting ===');

    // 1. Core initializations that must be completed before UI starts
    await _initFirebase();
    setupLocator();

    final authProvider = AuthProvider();
    await authProvider.initialize();
    final router = createRouter(authProvider);

    // 2. Heavy system, permission, and notification tasks triggered in the background
    _lockOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (!authProvider.isAuthenticated) {
      // Only attempt guest Ably initialization when network is available.
      NetworkService().checkNow().then((online) {
        if (online) {
          debugPrint('[Main] Guest user — initialising Ably as guest');
          ablyService.initAblyGuest().catchError(
            (Object e) => debugPrint('[Main] Guest Ably init failed: $e'),
          );
        } else {
          debugPrint('[Main] Skipping guest Ably init (offline)');
        }
      });
    }

    notificationService.init().catchError((e) {
      debugPrint('[Main] NotificationService initialization failed: $e');
    });

    debugPrint('[Main] Boot complete — running app');
    runApp(CampusChowApp(authProvider: authProvider, router: router));
  } catch (e, stack) {
    // Surface a visible error screen instead of a blank/crashed app.
    debugPrint('[Main] CRITICAL STARTUP ERROR\n$e\n$stack');
    runApp(StartupErrorApp(error: e.toString()));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Init helpers — keep main() a high-level script, not an implementation dump
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the background handler before any other FCM call.
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  // Crashlytics: non-fatal Flutter framework errors.
  FlutterError.onError = (details) {
    final exceptionStr = details.exception.toString();
    final isImageError =
        details.library == 'image resource service' ||
        exceptionStr.contains('HttpException: Invalid statusCode:') ||
        exceptionStr.contains('Unable to load asset') ||
        exceptionStr.contains('NetworkImage') ||
        exceptionStr.contains('image_stream.dart') ||
        exceptionStr.contains('res.cloudinary.com');

    if (isImageError) {
      debugPrint(
        '[Crashlytics] Suppressed expected image resource/network error: $exceptionStr',
      );
      return;
    }

    FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  // Crashlytics: non-fatal async errors outside the Flutter framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString();
    final isImageError =
        errorStr.contains('HttpException: Invalid statusCode:') ||
        errorStr.contains('NetworkImage') ||
        errorStr.contains('CachedNetworkImage') ||
        errorStr.contains('res.cloudinary.com');

    if (isImageError) {
      debugPrint(
        '[Crashlytics] Suppressed async image/network error: $errorStr',
      );
      return true; // handled
    }

    FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    return true;
  };
}

Future<void> _lockOrientation() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// CampusChowApp
// ─────────────────────────────────────────────────────────────────────────────

class CampusChowApp extends StatelessWidget {
  const CampusChowApp({
    super.key,
    required this.authProvider,
    required this.router,
  });

  final AuthProvider authProvider;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth is pre-built and shared; use .value so we don't own its lifecycle.
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Customer providers
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProxyProvider<StoreProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, storeProvider, cartProvider) {
            cartProvider!.updatePricing(
              meatPrices: storeProvider.meatPrices,
              saladPrice: storeProvider.saladPrice,
              allMenuItems: storeProvider.menuItems,
              allStores: storeProvider.stores,
            );
            return cartProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, authProvider, orderProvider) {
            orderProvider!.initialize(authProvider.user?.id);
            return orderProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => RiderJobProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // Store-dashboard providers
        ChangeNotifierProvider(create: (_) => dashboard_store.StoreProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_orders.OrderProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_cart.CartProvider()),
        ChangeNotifierProvider(
          create: (_) => dashboard_notifications.NotificationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => dashboard_staff.StaffProvider()),
      ],
      // Rebuilds only the MaterialApp.router when the theme changes.
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, _) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'CampusChow',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: router,
              builder: (context, child) {
                return NetworkStatusOverlay(child: child!);
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StartupErrorApp — last-resort fallback if boot fails
// ─────────────────────────────────────────────────────────────────────────────

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                  'The app could not start correctly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
