import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import 'package:campuschow/firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:campuschow/locator.dart';
import 'package:campuschow/theme/app_theme.dart';

import 'package:campuschow/providers/auth_provider.dart';
import 'package:campuschow/providers/theme_provider.dart';
import 'package:campuschow/providers/notification_provider.dart';

import 'package:campuschow/providers/store_provider.dart';
import 'package:campuschow/providers/cart_provider.dart';
import 'package:campuschow/providers/rider_job_provider.dart';
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

/// ─────────────────────────────────────────────────────────
/// LOCAL NOTIFICATIONS
/// ─────────────────────────────────────────────────────────

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications.',
  importance: Importance.high,
);

const AndroidNotificationChannel orderChannel =
    AndroidNotificationChannel(
  'launchfast_order_channel',
  'Order Notifications',
  description: 'Used for order updates and alerts.',
  importance: Importance.max,
);

/// ─────────────────────────────────────────────────────────
/// BACKGROUND FCM HANDLER
/// ─────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('[FCM] Background message: ${message.messageId}');
  debugPrint('[FCM] Data: ${message.data}');

  // Avoid duplicate notifications
  if (message.notification != null) {
    return;
  }

  if (message.data.isEmpty) return;

  final type = message.data['type'];
  final orderId = message.data['orderId'] ?? message.data['id'];

  String? title;
  String? body;

  switch (type) {
    case 'payment_success':
    case 'payment_alert':
      title = 'Payment Successful';
      body = 'Your payment for order #$orderId was confirmed.';
      break;

    case 'order_update':
    case 'order_processing':
      final status =
          message.data['status']?.toString().toLowerCase() ?? '';

      title = type == 'order_processing'
          ? 'Order Processing'
          : 'Order Updated';

      body = status.isNotEmpty
          ? 'Your order status is now: ${status.replaceAll("_", " ")}'
          : 'Your order is being processed.';
      break;

    case 'deposit':
      final amount = message.data['amount'];

      title = 'Deposit Successful';

      body = amount != null
          ? '₦$amount has been added to your wallet.'
          : 'Your wallet has been topped up successfully.';
      break;

    case 'new_order':
      title = 'New Order Received!';
      body = 'A customer just placed a new order.';
      break;
  }

  if (title == null || body == null) return;

  const androidDetails = AndroidNotificationDetails(
    'launchfast_order_channel',
    'Order Notifications',
    channelDescription: 'Channel for order notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  await flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: notificationDetails,
    payload: orderId?.toString(),
  );
}

/// ─────────────────────────────────────────────────────────
/// MAIN
/// ─────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('=== CampusChow Booting ===');

    /// Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    /// Background messages
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    /// Local notifications init
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint(
          '[Notification Clicked] Payload: ${details.payload}',
        );

        final payload = details.payload;

        if (payload != null && payload.isNotEmpty) {
          rootNavigatorKey.currentState?.pushNamed(
            '/order-details',
            arguments: payload,
          );
        }
      },
    );

    /// Android notification channels
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);

    /// Request notification permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    /// Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '[FCM] Foreground notification: ${message.messageId}',
      );

      final notification = message.notification;

      if (notification == null) return;

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
            'Used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title,
        body: notification.body,
        notificationDetails: notificationDetails,
      );
    });

    /// Notification opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background');

      final orderId =
          message.data['orderId'] ?? message.data['id'];

      if (orderId != null) {
        rootNavigatorKey.currentState?.pushNamed(
          '/order-details',
          arguments: orderId,
        );
      }
    });

    /// Notification opened from terminated state
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('[FCM] Opened from terminated state');

      final orderId =
          initialMessage.data['orderId'] ??
              initialMessage.data['id'];

      if (orderId != null) {
        Future.delayed(const Duration(seconds: 1), () {
          rootNavigatorKey.currentState?.pushNamed(
            '/order-details',
            arguments: orderId,
          );
        });
      }
    }

    /// Global Flutter errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exception}');
    };

    /// Platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[PlatformError] $error');
      return true;
    };

    /// Lock orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    /// Dependency injection
    setupLocator();

    /// Auth provider
    final authProvider = AuthProvider();

    await authProvider.initialize();

    /// Guest Ably init
    if (!authProvider.isAuthenticated) {
      debugPrint(
        '[Main] User unauthenticated, initializing guest Ably...',
      );

      ablyService.initAblyGuest().catchError((e) {
        debugPrint('[Main] Guest Ably init failed: $e');
      });
    }

    /// Router
    final router = createRouter(authProvider);

    /// Existing notification service
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

    runApp(
      StartupErrorApp(
        error: e.toString(),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// MAIN APP WIDGET
/// ─────────────────────────────────────────────────────────

class CampusChowApp extends StatelessWidget {
  final AuthProvider authProvider;
  final GoRouter router;

  const CampusChowApp({
    super.key,
    required this.authProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => RiderJobProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // Dashboard providers
        ChangeNotifierProvider(create: (_) => dashboard_store.StoreProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_orders.OrderProvider()),
        ChangeNotifierProvider(create: (_) => dashboard_cart.CartProvider()),
        ChangeNotifierProvider(
          create: (_) => dashboard_notifications.NotificationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => dashboard_staff.StaffProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'CampusChow',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                routerConfig: router,
              );
            },
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// STARTUP ERROR APP
/// ─────────────────────────────────────────────────────────

class StartupErrorApp extends StatelessWidget {
  final String error;

  const StartupErrorApp({
    super.key,
    required this.error,
  });

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
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The app could not start correctly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
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
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
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