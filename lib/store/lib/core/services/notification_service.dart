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
import 'package:campuschow/store/lib/features/dashboard/presentation/store_order_detail_screen.dart';

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
    debugPrint(
      '[NotificationService] init() start — platform=${Platform.operatingSystem}',
    );
    await _initLocalNotifications();
    if (Platform.isAndroid) await _requestAndroidPermission();
    await _initFcm();
    await _logFcmToken();
    await subscribeToTopic('broadcast');
    debugPrint('[NotificationService] init() complete');
  }

  // ── Local notifications ────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    debugPrint('[NotificationService] Initializing local notifications...');
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
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
    debugPrint('[NotificationService] Local notifications initialized');

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
      debugPrint('[FCM] _initFcm start');
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '[FCM] Permission settings: auth=${settings.authorizationStatus} '
        'alert=${settings.alert} badge=${settings.badge} sound=${settings.sound} '
        'announcement=${settings.announcement} carPlay=${settings.carPlay} '
        'criticalAlert=${settings.criticalAlert}',
      );

      // Show banners while in the foreground on iOS.
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] Foreground presentation options enabled');

      final currentSettings = await _fcm.getNotificationSettings();
      debugPrint(
        '[FCM] Current notification settings: auth=${currentSettings.authorizationStatus} '
        'alert=${currentSettings.alert} badge=${currentSettings.badge} '
        'sound=${currentSettings.sound}',
      );

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          '[FCM] onMessage fired — id=${message.messageId} '
          'from=${message.from} sentTime=${message.sentTime} '
          'hasNotification=${message.notification != null} data=${message.data}',
        );
        _onForegroundMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        debugPrint(
          '[FCM] App opened from background tap — id=${msg.messageId} data=${msg.data}',
        );
        _onNotificationTap(msg);
      });

      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        debugPrint(
          '[FCM] App launched from notification tap — id=${initial.messageId} data=${initial.data}',
        );
        // Defer so the widget tree is mounted before we push a route.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _onNotificationTap(initial),
        );
      } else {
        debugPrint('[FCM] No initial launch notification');
      }

      _fcm.onTokenRefresh.listen((token) {
        debugPrint('[FCM] onTokenRefresh emitted token=$token');
        _onTokenRefresh(token);
      });
      debugPrint('[FCM] _initFcm complete');
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
    debugPrint(
      '[FCM] Foreground handler start — id=${message.messageId} '
      'data=${message.data} title=${message.notification?.title} '
      'body=${message.notification?.body}',
    );

    // Deduplicate.
    final id = message.messageId;
    if (id != null) {
      if (_handledMessageIds.contains(id)) {
        debugPrint('[FCM] Duplicate foreground message ignored: $id');
        return;
      }
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
    debugPrint('[FCM] In-app listeners notified with payload=$combinedData');

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
      debugPrint('[FCM] Foreground local notification displayed');
    } else {
      debugPrint('[FCM] Entering data-only message handler');
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
    debugPrint(
      '[FCM] Handling data-only message — type=$type orderId=$orderId status=$status amount=$amount data=${message.data}',
    );

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
      default:
        debugPrint('[FCM] Unhandled data-only type: $type');
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
      String cleanId = id;
      if (cleanId.startsWith('order_')) {
        cleanId = cleanId.replaceFirst('order_', '');
      }
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => StoreOrderDetailScreen(orderId: cleanId),
        ),
      );
    }
  }

  // ── Token helpers ──────────────────────────────────────────────────────────

  Future<void> _logFcmToken() async {
    try {
      if (Platform.isIOS) {
        debugPrint('[FCM] iOS Platform detected. Requesting APNS token...');

        // Sometimes APNS registration takes a split second at startup.
        // Let's retry a few times to get the token.
        String? apnsToken;
        for (int i = 0; i < 3; i++) {
          apnsToken = await _fcm.getAPNSToken();
          if (apnsToken != null) break;
          debugPrint(
            '[FCM] APNS token not ready yet. Retrying in 2 seconds (attempt ${i + 1}/3)...',
          );
          await Future.delayed(const Duration(seconds: 2));
        }

        debugPrint('[FCM] APNS token after retries: $apnsToken');
        if (apnsToken == null) {
          debugPrint(
            '[FCM CRITICAL WARNING] APNS token is null! iOS push notifications will NOT work. \n'
            'Checklist of common reasons:\n'
            '1. Testing on a Simulator (Simulators do not support remote push notifications).\n'
            '2. Xcode capability "Push Notifications" is missing.\n'
            '3. Xcode capability "Background Modes" -> "Remote notifications" is unchecked.\n'
            '4. Mismatch in Provisioning Profile (e.g. Debug build vs Production aps-environment entitlement).',
          );
        } else {
          debugPrint(
            '[FCM SUCCESS] APNS token retrieved successfully: $apnsToken',
          );
        }
      }

      final token = await _fcm.getToken();
      debugPrint('[FCM] Registration Token (FCM): $token');
      if (token == null) {
        debugPrint(
          '[FCM CRITICAL WARNING] FCM registration token is null! Cannot receive push notifications.',
        );
      } else {
        debugPrint(
          '[FCM SUCCESS] FCM registration token retrieved successfully: $token',
        );
      }
    } catch (e, stack) {
      debugPrint('[FCM ERROR] Exception during token retrieval: $e\n$stack');
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
    debugPrint(
      '[NotificationService] showNotification title=$title body=$body payload=$payload channelId=$channelId',
    );
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool(_kSoundPrefKey) ?? true;
    final soundFile = soundEnabled ? 'order_sound' : null;
    debugPrint(
      '[NotificationService] soundEnabled=$soundEnabled soundFile=$soundFile',
    );

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
    debugPrint('[NotificationService] Local notification posted successfully');
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
    debugPrint(
      '[NotificationService] showStaticNotification title=$title body=$body payload=$payload',
    );
    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'order_sound.mp3',
      ),
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
