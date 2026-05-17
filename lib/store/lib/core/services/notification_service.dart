import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campuschow/locator.dart';
import 'package:campuschow/repositories/auth_repository.dart';
import 'package:campuschow/router.dart';
import 'package:campuschow/services/ably_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Channel identifiers (package-level constants — referenced by main.dart too)
// ─────────────────────────────────────────────────────────────────────────────

const kHighImportanceChannelId = 'high_importance_channel';
const kOrderChannelId = 'launchfast_order_channel';

// ─────────────────────────────────────────────────────────────────────────────
// Preference key
// ─────────────────────────────────────────────────────────────────────────────

const _kSoundPrefKey = 'order_notifications_sound';

// ─────────────────────────────────────────────────────────────────────────────
// Type alias for in-app notification listener
// ─────────────────────────────────────────────────────────────────────────────

typedef NotificationListener = void Function(Map<String, dynamic> data);

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

/// Singleton service that owns FCM + local-notification lifecycle.
///
/// Usage:
/// ```dart
/// await notificationService.init();
/// ```
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  // ── Plugin instances ────────────────────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ── Deduplication ──────────────────────────────────────────────────────────
  /// Keeps at most [_kMaxHandledIds] message IDs to prevent duplicate
  /// foreground notifications. Cleared when the threshold is hit.
  static const int _kMaxHandledIds = 100;
  final Set<String> _handledMessageIds = {};

  // ── In-app listeners ───────────────────────────────────────────────────────
  final List<NotificationListener> _listeners = [];

  // ── Public API: listeners ──────────────────────────────────────────────────

  void addListener(NotificationListener listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  void removeListener(NotificationListener listener) =>
      _listeners.remove(listener);

  void _notifyListeners(Map<String, dynamic> data) {
    // Iterate over a copy so listeners can safely remove themselves.
    for (final listener in List.of(_listeners)) {
      listener(data);
    }
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _initLocalNotifications();
    if (Platform.isAndroid) await _requestAndroidPermission();
    await _initFcm();
    await _logFcmToken();
    await subscribeToTopic('broadcast');
  }

  // ── Local notifications ────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    await _createAndroidChannels();
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('[Notification] Tapped — payload=${response.payload}');
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _navigate(type: null, id: payload);
    }
  }

  Future<void> _createAndroidChannels() async {
    final plugin = _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (plugin == null) return;

    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        kHighImportanceChannelId,
        'High Importance Notifications',
        description: 'Used for important notifications',
        importance: Importance.high,
      ),
    );

    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        kOrderChannelId,
        'Order Notifications',
        description: 'Used for order alerts and updates',
        importance: Importance.max,
      ),
    );
  }

  Future<void> _requestAndroidPermission() async {
    await _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // ── FCM ────────────────────────────────────────────────────────────────────

  Future<void> _initFcm() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      // Show banners while in the foreground on iOS.
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        debugPrint('[FCM] App opened from background tap');
        _onNotificationTap(msg);
      });

      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        debugPrint('[FCM] App launched from notification tap');
        // Defer so the widget tree is mounted before we push a route.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _onNotificationTap(initial),
        );
      }

      _fcm.onTokenRefresh.listen(_onTokenRefresh);
    } catch (e, stack) {
      debugPrint('[FCM] _initFcm error: $e\n$stack');
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    debugPrint('[FCM] Token refreshed');
    try {
      await locator<AuthRepository>().updateProfile({
        'fcmToken': token,
        'deviceToken': token,
      });
      debugPrint('[FCM] Refreshed token synced to backend');
    } catch (e) {
      debugPrint('[FCM] Failed to sync refreshed token: $e');
    }
  }

  // ── Foreground messages ────────────────────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground — id=${message.messageId}');

    // Deduplicate.
    final id = message.messageId;
    if (id != null) {
      if (_handledMessageIds.contains(id)) return;
      _handledMessageIds.add(id);
      if (_handledMessageIds.length > _kMaxHandledIds) {
        _handledMessageIds.clear();
      }
    }

    // Build combined payload for in-app listeners.
    final combinedData = Map<String, dynamic>.from(message.data);
    if (message.notification case final n?) {
      combinedData['title'] = n.title;
      combinedData['body'] = n.body;
    }
    _notifyListeners(combinedData);

    // Wallet side-effect.
    _maybeNotifyWallet(message.data['type'] as String?);

    // Show local notification.
    if (message.notification case final n?) {
      await showNotification(
        title: n.title ?? 'New Notification',
        body: n.body ?? '',
        payload: (message.data['orderId'] ?? message.data['id']) as String?,
        channelId: kHighImportanceChannelId,
      );
    } else {
      await _handleDataOnlyMessage(message);
    }
  }

  void _maybeNotifyWallet(String? type) {
    const walletTypes = {
      'wallet_update',
      'wallet_topup',
      'walletUpdate',
      'deposit',
    };
    if (type != null && walletTypes.contains(type)) {
      debugPrint('[FCM] Wallet update detected');
      ablyService.notifyWalletUpdate();
    }
  }

  // ── Data-only messages ─────────────────────────────────────────────────────

  Future<void> _handleDataOnlyMessage(RemoteMessage message) async {
    final type = message.data['type'] as String?;
    final orderId = (message.data['orderId'] ?? message.data['id']) as String?;
    final status = (message.data['status'] as String?)?.toLowerCase() ?? '';
    final amount = message.data['amount'] as String?;

    switch (type) {
      case 'deposit':
        await showNotification(
          title: 'Deposit Successful',
          body: amount != null
              ? '₦$amount has been added to your wallet.'
              : 'Your wallet has been topped up successfully.',
          payload: 'wallet',
          channelId: kHighImportanceChannelId,
        );

      case 'order_update':
      case 'order_processing':
        await showNotification(
          title: type == 'order_processing'
              ? 'Order Processing'
              : 'Order Updated',
          body: status.isNotEmpty
              ? 'Your order status is now: ${status.replaceAll('_', ' ')}'
              : 'Your order is being processed.',
          payload: orderId,
          channelId: kOrderChannelId,
        );

      case 'new_order':
        await showNotification(
          title: 'New Order Received!',
          body: 'A customer just placed a new order.',
          payload: orderId,
          channelId: kOrderChannelId,
        );

      case 'payment_success':
      case 'payment_alert':
        await showNotification(
          title: 'Payment Successful',
          body: 'Payment confirmed for order #$orderId',
          payload: orderId,
        );
        break;
    }
  }

  // ── Notification tap ───────────────────────────────────────────────────────

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tap — data=${message.data}');
    _navigate(
      type: message.data['type'] as String?,
      id: (message.data['orderId'] ?? message.data['id']) as String?,
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigate({required String? type, required String? id}) {
    debugPrint('[Notification] Navigate — type=$type, id=$id');

    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('[Notification] Navigation skipped: context is null');
      return;
    }

    if (type == 'deposit' || id == 'wallet') {
      context.push(routeTransactions);
      return;
    }

    if (id != null && id.isNotEmpty) {
      context.push('/order-details/$id');
    }
  }

  // ── Token helpers ──────────────────────────────────────────────────────────

  Future<void> _logFcmToken() async {
    try {
      if (Platform.isIOS) {
        final apns = await _fcm.getAPNSToken();
        debugPrint('[FCM] APNS token: $apns');
        if (apns == null) {
          debugPrint(
            '[FCM] APNS token is null — push will not work on simulators.',
          );
        }
      }
      final token = await _fcm.getToken();
      debugPrint('[FCM] Token: $token');
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  // ── Topic subscriptions ────────────────────────────────────────────────────

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to: $topic');
    } catch (e) {
      debugPrint('[FCM] subscribeToTopic($topic) error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from: $topic');
    } catch (e) {
      debugPrint('[FCM] unsubscribeFromTopic($topic) error: $e');
    }
  }

  Future<void> subscribeToUserTopic(String userId) async {
    await subscribeToTopic('user_${_sanitizeTopic(userId)}');
  }

  Future<void> unsubscribeFromUserTopic(String userId) async {
    await unsubscribeFromTopic('user_${_sanitizeTopic(userId)}');
  }

  Future<void> subscribeToStoreAdminTopic(String storeId) async {
    await subscribeToTopic('store_admin_$storeId');
  }

  Future<void> unsubscribeFromStoreAdminTopic(String storeId) async {
    await unsubscribeFromTopic('store_admin_$storeId');
  }

  static String _sanitizeTopic(String id) =>
      id.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');

  // ── Show local notification ────────────────────────────────────────────────

  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String channelId = kHighImportanceChannelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool(_kSoundPrefKey) ?? true;
    final soundFile = soundEnabled ? 'order_sound' : null;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId == kOrderChannelId
            ? 'Order Notifications'
            : 'High Importance Notifications',
        channelDescription: 'CampusChow notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: soundEnabled,
        enableVibration: true,
        sound: soundFile != null
            ? RawResourceAndroidNotificationSound(soundFile)
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundEnabled,
        sound: soundFile != null ? '$soundFile.mp3' : null,
      ),
    );

    await _localPlugin.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // ── Static notification (background isolates) ──────────────────────────────

  /// Shows a notification from a background isolate where the singleton
  /// instance is not available. Creates its own plugin instance and
  /// re-initialises it (safe to call multiple times per isolate).
  static Future<void> showStaticNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        kHighImportanceChannelId,
        'Notifications',
        channelDescription: 'CampusChow notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // Mask to valid int32 range so Android doesn't reject the ID.
    final safeId =
        (id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF;

    await plugin.show(
      id: safeId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Singleton accessor
// ─────────────────────────────────────────────────────────────────────────────

final notificationService = NotificationService();
