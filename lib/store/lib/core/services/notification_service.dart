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

        final String? type = message.data['type'];
        final String? orderId = message.data['orderId'];

        // Handle wallet updates/deposits automatically
        if (type == 'wallet_update' || type == 'deposit') {
          debugPrint('[FCM] Wallet update detected, triggering refresh');
          ablyService.notifyWalletUpdate();
        }

        if (message.notification != null) {
          showNotification(
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
            payload: orderId,
          );
        } else if (type == 'deposit') {
          // If backend sends data-only message for deposit, still show notification
          final amount = message.data['amount'];
          showNotification(
            title: 'Deposit Successful',
            body: amount != null 
                ? '₦$amount has been added to your wallet.' 
                : 'Your wallet has been topped up successfully.',
            payload: 'wallet',
          );
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

