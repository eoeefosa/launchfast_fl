import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

import 'package:campuschow/store/lib/core/providers/notification_provider.dart'
    as dashboard_notifications;
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'package:campuschow/store/lib/features/dashboard/presentation/staff_provider.dart'
    as dashboard_staff;
import 'package:campuschow/store/lib/features/orders/presentation/cart_provider.dart'
    as dashboard_cart;
import 'package:campuschow/store/lib/features/orders/presentation/order_provider.dart'
    as dashboard_orders;
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart'
    as dashboard_store;

// ─────────────────────────────────────────────────────────────────────────────
// Globals — only what truly must be global
// ─────────────────────────────────────────────────────────────────────────────

/// Root navigator key exposed to the router.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Plugin instance shared across main and background isolate.
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ─────────────────────────────────────────────────────────────────────────────
// Android notification channels
// ─────────────────────────────────────────────────────────────────────────────

const _highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications.',
  importance: Importance.high,
);

const _orderChannel = AndroidNotificationChannel(
  'launchfast_order_channel',
  'Order Notifications',
  description: 'Used for order updates and alerts.',
  importance: Importance.max,
);

// ─────────────────────────────────────────────────────────────────────────────
// Background FCM handler — must be a top-level function
// ─────────────────────────────────────────────────────────────────────────────

/// Runs in a separate Dart isolate; keep it lean.
/// Firebase must be re-initialised here because it is a fresh isolate.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('[FCM-BG] id=${message.messageId} data=${message.data}');

  // FCM already displayed a notification for messages that carry a
  // `notification` payload — avoid showing a duplicate.
  if (message.notification != null) return;
  if (message.data.isEmpty) return;

  final (title, body) = _resolveNotificationCopy(message.data);
  if (title == null || body == null) return;

  final orderId = message.data['orderId'] ?? message.data['id'];

  await NotificationService.showStaticNotification(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    payload: orderId?.toString(),
  );
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

  try {
    debugPrint('=== CampusChow Booting ===');

    await _initFirebase();
    await _initLocalNotifications();
    await _initFcmPermissionsAndListeners();
    await _lockOrientation();

    setupLocator();

    final authProvider = AuthProvider();
    await authProvider.initialize();

    if (!authProvider.isAuthenticated) {
      debugPrint('[Main] Guest user — initialising Ably as guest');
      // Fire-and-forget; a failed Ably init must not crash the app.
      ablyService.initAblyGuest().catchError(
            (Object e) => debugPrint('[Main] Guest Ably init failed: $e'),
          );
    }

    await notificationService.init();

    final router = createRouter(authProvider);

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background handler before any other FCM call.
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  // Crashlytics: fatal Flutter framework errors.
  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Crashlytics: fatal async errors outside the Flutter framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _initLocalNotifications() async {
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  await _localNotifications.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  // Create Android channels (no-op on iOS/other platforms).
  final androidPlugin = _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(_highImportanceChannel);
  await androidPlugin?.createNotificationChannel(_orderChannel);
}

/// Called when the user taps a local notification (foreground or background).
void _onNotificationTapped(NotificationResponse response) {
  debugPrint('[Notification] Tapped — payload=${response.payload}');

  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  // Use GoRouter's global navigation helper so we stay inside the router graph.
  rootNavigatorKey.currentContext?.go('/order-details/$payload');
}

Future<void> _initFcmPermissionsAndListeners() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // App opened via notification tap while in background.
  FirebaseMessaging.onMessageOpenedApp.listen(_navigateToOrder);

  // App launched from a terminated state via notification tap.
  final initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    // Delay so the widget tree (and router) have time to mount.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _navigateToOrder(initialMessage),
    );
  }
}

/// Common handler for FCM deep-link navigation.
void _navigateToOrder(RemoteMessage message) {
  final orderId = message.data['orderId'] ?? message.data['id'];
  if (orderId == null) return;

  debugPrint('[FCM] Navigating to order: $orderId');
  rootNavigatorKey.currentContext?.go('/order-details/$orderId');
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
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
            builder: (_, __) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'CampusChow',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: router,
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