import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuschow/services/ably_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  NotificationService._internal();

  final List<void Function(Map<String, dynamic> data)> _listeners = [];

  void addListener(void Function(Map<String, dynamic> data) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(void Function(Map<String, dynamic> data) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(Map<String, dynamic> data) {
    for (final listener in _listeners) {
      listener(data);
    }
  }

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // --- FCM Initialization ---
    await _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      // 1. Request permissions (especially for iOS)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[FCM] User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('[FCM] User granted provisional permission');
      } else {
        debugPrint('[FCM] User declined or has not accepted permission');
      }

      // 2. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message received: ${message.notification?.title}');
        debugPrint('[FCM] Data: ${message.data}');

        // Notify in-app listeners (to add to notification list)
        final Map<String, dynamic> combinedData = Map.from(message.data);
        if (message.notification != null) {
          combinedData['title'] = message.notification!.title;
          combinedData['body'] = message.notification!.body;
        }
        _notifyListeners(combinedData);

        final String? type = message.data['type'];
        final String? orderId = message.data['orderId'] ?? message.data['id'];

        // Handle wallet updates/deposits automatically
        if (type == 'wallet_update' || type == 'deposit') {
          debugPrint('[FCM] Wallet update detected, triggering refresh');
          ablyService.notifyWalletUpdate();
        }

        // Show local notification if it's a data-only message or we want custom behavior
        if (message.notification != null) {
          showNotification(
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
            payload: orderId,
          );
        } else if (type != null) {
          // Handle various data-only message types from backend
          switch (type) {
            case 'deposit':
              final amount = message.data['amount'];
              showNotification(
                title: 'Deposit Successful',
                body: amount != null 
                    ? '₦$amount has been added to your wallet.' 
                    : 'Your wallet has been topped up successfully.',
                payload: 'wallet',
              );
              break;
            case 'order_update':
            case 'order_processing':
              final status = message.data['status']?.toString().toLowerCase() ?? '';
              showNotification(
                title: type == 'order_processing' ? 'Order Processing' : 'Order Updated',
                body: status.isNotEmpty 
                    ? 'Your order status is now: ${status.replaceAll("_", " ")}'
                    : 'Your order is being processed.',
                payload: orderId,
              );
              break;
            case 'new_order':
              showNotification(
                title: 'New Order Received!',
                body: 'A customer just placed a new order.',
                payload: orderId,
              );
              break;
            case 'payment_success':
            case 'payment_alert':
              showNotification(
                title: 'Payment Successful',
                body: 'Your payment for order #$orderId was confirmed.',
                payload: orderId,
              );
              break;
          }
        }
      });

      // 3. Handle notification click when app is in background but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Message clicked: ${message.data}');
      });

    } catch (e) {
      debugPrint('[FCM] Init error: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
      return null;
    }
  }

  // ── Topic subscription helpers ──────────────────────────────────────────────
  //
  // The backend sends notifications via FCM topics. The device MUST subscribe
  // to each topic explicitly, otherwise the message is silently dropped.

  /// Subscribe a customer/authenticated user to their personal push topic.
  /// Call this immediately after login / session restore.
  Future<void> subscribeToUserTopic(String userId) async {
    try {
      // Replicate the backend sanitization from lib/services/notifications.ts:
      // userId.replace(/[^a-zA-Z0-9-_.~%]/g, '_')
      final sanitized = userId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
      final topic = 'user_$sanitized';
      await _fcm.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] subscribeToUserTopic error: $e');
    }
  }

  /// Unsubscribe when the user logs out so they stop receiving push alerts.
  Future<void> unsubscribeFromUserTopic(String userId) async {
    try {
      final sanitized = userId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
      final topic = 'user_$sanitized';
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] unsubscribeFromUserTopic error: $e');
    }
  }

  /// Subscribe a store owner to their store-specific order alert topic.
  /// Topic format mirrors the backend: store_admin_{storeId}
  /// Call this after the store owner's owned store ID is known.
  Future<void> subscribeToStoreAdminTopic(String storeId) async {
    try {
      final topic = 'store_admin_$storeId';
      await _fcm.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to store admin topic: $topic');
    } catch (e) {
      debugPrint('[FCM] subscribeToStoreAdminTopic error: $e');
    }
  }

  /// Unsubscribe from the store admin topic on logout or store switch.
  Future<void> unsubscribeFromStoreAdminTopic(String storeId) async {
    try {
      final topic = 'store_admin_$storeId';
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from store admin topic: $topic');
    } catch (e) {
      debugPrint('[FCM] unsubscribeFromStoreAdminTopic error: $e');
    }
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isSoundEnabled = prefs.getBool('order_notifications_sound') ?? true;

    // We specify 'order_sound' here. 
    // Android looks in: res/raw/order_sound.mp3
    // iOS looks in: the main bundle for order_sound.aiff/mp3/wav
    final String? soundFile = isSoundEnabled ? 'order_sound' : null;

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'launchfast_order_channel',
      'Order Notifications',
      channelDescription: 'Channel for new order alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: isSoundEnabled,
      sound: soundFile != null ? RawResourceAndroidNotificationSound(soundFile) : null,
    );

    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentSound: isSoundEnabled,
      sound: soundFile != null ? '$soundFile.mp3' : null,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}

final notificationService = NotificationService();


