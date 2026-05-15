import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campuschow/services/ably_service.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _fcm =
      FirebaseMessaging.instance;

  /// Prevent duplicate foreground notifications
  final Set<String> _handledMessageIds = {};

  /// In-app listeners
  final List<void Function(Map<String, dynamic> data)>
      _listeners = [];

  /// Notification channel IDs
  static const String highImportanceChannelId =
      'high_importance_channel';

  static const String orderChannelId =
      'launchfast_order_channel';

  /// ─────────────────────────────────────────────────────
  /// LISTENERS
  /// ─────────────────────────────────────────────────────

  void addListener(
    void Function(Map<String, dynamic> data) listener,
  ) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(
    void Function(Map<String, dynamic> data) listener,
  ) {
    _listeners.remove(listener);
  }

  void _notifyListeners(
    Map<String, dynamic> data,
  ) {
    for (final listener in _listeners) {
      listener(data);
    }
  }

  /// ─────────────────────────────────────────────────────
  /// INIT
  /// ─────────────────────────────────────────────────────

  Future<void> init() async {
    await _initializeLocalNotifications();

    if (Platform.isAndroid) {
      await _requestAndroidNotificationPermission();
    }

    await _initFCM();

    await _printFCMToken();

    // Automatically subscribe to the global broadcast topic
    await subscribeToTopic('broadcast');
  }

  /// ─────────────────────────────────────────────────────
  /// LOCAL NOTIFICATIONS
  /// ─────────────────────────────────────────────────────

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {
        debugPrint(
          '[Notification Clicked] ${response.payload}',
        );

        // TODO:
        // Add GoRouter navigation here if needed
      },
    );

    /// Create Android notification channels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    /// High priority channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        highImportanceChannelId,
        'High Importance Notifications',
        description:
            'Used for important notifications',
        importance: Importance.high,
      ),
    );

    /// Orders channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        orderChannelId,
        'Order Notifications',
        description:
            'Used for order alerts and updates',
        importance: Importance.max,
      ),
    );
  }

  Future<void>
      _requestAndroidNotificationPermission() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// ─────────────────────────────────────────────────────
  /// FCM INIT
  /// ─────────────────────────────────────────────────────

  Future<void> _initFCM() async {
    try {
      /// Request permissions
      final settings =
          await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '[FCM] Permission: ${settings.authorizationStatus}',
      );

      /// Force iOS to show banner/alert when app is in the foreground
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      /// Foreground notifications
      FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      /// Notification opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          debugPrint(
            '[FCM] Opened from background',
          );

          _handleNotificationTap(message);
        },
      );

      /// Notification opened from terminated state
      final initialMessage =
          await _fcm.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          '[FCM] Opened from terminated state',
        );

        _handleNotificationTap(initialMessage);
      }

      /// Token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint(
          '[FCM] Token refreshed: $newToken',
        );

        // TODO:
        // Send refreshed token to backend
      });
    } catch (e) {
      debugPrint('[FCM] Init error: $e');
    }
  }

  /// ─────────────────────────────────────────────────────
  /// FOREGROUND MESSAGE HANDLER
  /// ─────────────────────────────────────────────────────

  Future<void> _handleForegroundMessage(
    RemoteMessage message,
  ) async {
    debugPrint(
      '[FCM] Foreground message: ${message.messageId}',
    );

    debugPrint(
      '[FCM] Data: ${message.data}',
    );

    /// Prevent duplicate notifications
    final messageId = message.messageId;

    if (messageId != null &&
        _handledMessageIds.contains(messageId)) {
      return;
    }

    if (messageId != null) {
      _handledMessageIds.add(messageId);
    }

    /// Cleanup old IDs
    if (_handledMessageIds.length > 100) {
      _handledMessageIds.clear();
    }

    /// Notify in-app listeners
    final Map<String, dynamic> combinedData =
        Map.from(message.data);

    if (message.notification != null) {
      combinedData['title'] =
          message.notification?.title;

      combinedData['body'] =
          message.notification?.body;
    }

    _notifyListeners(combinedData);

    /// Wallet updates
    final type = message.data['type'];

    if (type == 'wallet_update' ||
        type == 'deposit') {
      debugPrint(
        '[FCM] Wallet update detected',
      );

      ablyService.notifyWalletUpdate();
    }

    /// If Firebase already shows notification,
    /// don't duplicate it
    if (message.notification != null) {
      await showNotification(
        title:
            message.notification?.title ??
                'New Notification',
        body:
            message.notification?.body ?? '',
        payload:
            message.data['orderId'] ??
                message.data['id'],
        channelId: highImportanceChannelId,
      );

      return;
    }

    /// Handle data-only notifications
    await _handleDataOnlyNotification(message);
  }

  /// ─────────────────────────────────────────────────────
  /// DATA-ONLY NOTIFICATIONS
  /// ─────────────────────────────────────────────────────

  Future<void> _handleDataOnlyNotification(
    RemoteMessage message,
  ) async {
    final type = message.data['type'];

    final orderId =
        message.data['orderId'] ??
            message.data['id'];

    switch (type) {
      case 'deposit':
        final amount = message.data['amount'];

        await showNotification(
          title: 'Deposit Successful',
          body: amount != null
              ? '₦$amount has been added to your wallet.'
              : 'Your wallet has been topped up successfully.',
          payload: 'wallet',
          channelId: highImportanceChannelId,
        );
        break;

      case 'order_update':
      case 'order_processing':
        final status =
            message.data['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        await showNotification(
          title: type == 'order_processing'
              ? 'Order Processing'
              : 'Order Updated',
          body: status.isNotEmpty
              ? 'Your order status is now: ${status.replaceAll("_", " ")}'
              : 'Your order is being processed.',
          payload: orderId,
          channelId: orderChannelId,
        );
        break;

      case 'new_order':
        await showNotification(
          title: 'New Order Received!',
          body:
              'A customer just placed a new order.',
          payload: orderId,
          channelId: orderChannelId,
        );
        break;

      case 'payment_success':
      case 'payment_alert':
        await showNotification(
          title: 'Payment Successful',
          body:
              'Your payment for order #$orderId was confirmed.',
          payload: orderId,
          channelId: highImportanceChannelId,
        );
        break;
    }
  }

  /// ─────────────────────────────────────────────────────
  /// HANDLE NOTIFICATION TAPS
  /// ─────────────────────────────────────────────────────

  void _handleNotificationTap(
    RemoteMessage message,
  ) {
    debugPrint(
      '[FCM] Notification tap data: ${message.data}',
    );

    final type = message.data['type'];

    final orderId =
        message.data['orderId'] ??
            message.data['id'];

    switch (type) {
      case 'deposit':
        debugPrint(
          '[Navigation] Open wallet screen',
        );
        break;

      case 'new_order':
      case 'order_update':
      case 'order_processing':
      case 'payment_success':
        debugPrint(
          '[Navigation] Open order: $orderId',
        );
        break;
    }
  }

  /// ─────────────────────────────────────────────────────
  /// TOKEN
  /// ─────────────────────────────────────────────────────

  Future<void> _printFCMToken() async {
    try {
      if (Platform.isIOS) {
        // On iOS, we need to wait for APNS token before FCM token is available
        final apnsToken = await _fcm.getAPNSToken();
        debugPrint('[FCM] APNS Token: $apnsToken');
        
        if (apnsToken == null) {
          debugPrint('[FCM] WARNING: APNS token is null. Push notifications will NOT work.');
          debugPrint('[FCM] If on Simulator, this is expected behavior. Please test on a REAL device.');
        }
      }

      final token = await _fcm.getToken();
      debugPrint('[FCM TOKEN]');
      debugPrint(token);
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint(
        '[FCM] Error getting token: $e',
      );

      return null;
    }
  }

  /// ─────────────────────────────────────────────────────
  /// TOPIC SUBSCRIPTIONS
  /// ─────────────────────────────────────────────────────

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] subscribeToTopic error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] unsubscribeFromTopic error: $e');
    }
  }

  Future<void> subscribeToUserTopic(
    String userId,
  ) async {
    final sanitized = userId.replaceAll(
      RegExp(r'[^a-zA-Z0-9\-_.~%]'),
      '_',
    );
    await subscribeToTopic('user_$sanitized');
  }

  Future<void> unsubscribeFromUserTopic(
    String userId,
  ) async {
    final sanitized = userId.replaceAll(
      RegExp(r'[^a-zA-Z0-9\-_.~%]'),
      '_',
    );
    await unsubscribeFromTopic('user_$sanitized');
  }

  Future<void> subscribeToStoreAdminTopic(
    String storeId,
  ) async {
    await subscribeToTopic('store_admin_$storeId');
  }

  Future<void> unsubscribeFromStoreAdminTopic(
    String storeId,
  ) async {
    await unsubscribeFromTopic('store_admin_$storeId');
  }

  /// ─────────────────────────────────────────────────────
  /// SHOW LOCAL NOTIFICATION
  /// ─────────────────────────────────────────────────────

  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String channelId =
        highImportanceChannelId,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final bool isSoundEnabled =
        prefs.getBool(
              'order_notifications_sound',
            ) ??
            true;

    final String? soundFile =
        isSoundEnabled
            ? 'order_sound'
            : null;

    final androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelId ==
              orderChannelId
          ? 'Order Notifications'
          : 'High Importance Notifications',
      channelDescription:
          'CampusChow notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: isSoundEnabled,
      enableVibration: true,
      sound: soundFile != null
          ? RawResourceAndroidNotificationSound(
              soundFile,
            )
          : null,
    );

    final iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: isSoundEnabled,
      sound: soundFile != null
          ? '$soundFile.mp3'
          : null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}

final notificationService =
    NotificationService();
