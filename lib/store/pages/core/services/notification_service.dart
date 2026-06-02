import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:campuschow/locator.dart';
import 'package:campuschow/repositories/auth_repository.dart';
import 'package:campuschow/router.dart';
import 'package:campuschow/services/ably_service.dart';
import 'package:campuschow/store/pages/features/dashboard/presentation/store_order_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Channel identifiers (package-level constants — referenced by main.dart too)
// ─────────────────────────────────────────────────────────────────────────────

const kHighImportanceChannelId = 'high_importance_channel';
const kOrderChannelId = 'launchfast_order_channel';

// ─────────────────────────────────────────────────────────────────────────────
// Preference key
// ─────────────────────────────────────────────────────────────────────────────

const _kSoundPrefKey = 'order_notifications_sound';
const _kDailyReminderEnabledKey = 'daily_reminder_enabled';
const _kDailyReminderHourKey = 'daily_reminder_hour';
const _kDailyReminderMinuteKey = 'daily_reminder_minute';
const _kDailyReminderWindowKey = 'daily_reminder_window';

const kGentleChannelId = 'daily_gentle_channel';
const _kAnalyticsImpressions = 'analytics_notifications_impressions';
const _kAnalyticsOpens = 'analytics_notifications_opens';
const _kReminderStreakKey = 'reminder_streak';
const _kReminderLastOpenKey = 'reminder_last_open';

const _kReminderPayloadPrefix = 'reminders_daily';
const _kAdaptiveEnabledKey = 'daily_reminder_adaptive';
const _kOpenHistogramKey = 'daily_reminder_histogram'; // JSON encoded list of 24 ints
const _kRemoteToLocalPrefKey = 'notif_remote_to_local_map';

final List<Map<String, dynamic>> _reminderTemplates = [
  {
    'title': 'Breakfast ready? ☕️',
    'body': 'Grab a quick breakfast on your way to class — new campus combos available!',
    'slots': ['morning']
  },
  {
    'title': 'Study fuel time 🍳',
    'body': 'Fuel your study sesh with a hearty meal — check today\'s student picks.',
    'slots': ['morning', 'afternoon']
  },
  {
    'title': 'Lunch break deals 🍔',
    'body': 'Lunch specials nearby — save time and cash with quick pickup!',
    'slots': ['afternoon']
  },
  {
    'title': 'Snack attack? 🍟',
    'body': 'Late class? Grab a snack and recharge — hot bites waiting.',
    'slots': ['afternoon','evening']
  },
  {
    'title': 'Dinner sorted 🍲',
    'body': 'Dinner deals for tonight — hurry, limited portions!',
    'slots': ['evening']
  },
  {
    'title': 'Late-night cravings 🌙',
    'body': 'Pull an all-nighter? Order comfort food delivered fast.',
    'slots': ['late_night']
  },
  {
    'title': 'Streak bonus!',
    'body': 'You\'re on a roll — open the app for a surprise perk.',
    'slots': ['any']
  },
  {
    'title': 'Quick picks for students 🎓',
    'body': 'Budget-friendly student meals updated — check what\'s trending.',
    'slots': ['any']
  },
];

String _slotForHour(int hour) {
  if (hour >= 5 && hour < 10) return 'morning';
  if (hour >= 10 && hour < 15) return 'afternoon';
  if (hour >= 15 && hour < 19) return 'evening';
  if (hour >= 19 && hour < 24) return 'late_night';
  return 'morning';
}

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

  // FIX (cross-source dedup): a single new order can arrive via three paths in
  // parallel (Ably channel push, FCM data message, 30 s order poll). The
  // existing `_handledMessageIds` only catches FCM-vs-FCM. This map dedupes
  // OS-level notifications by an arbitrary key (e.g. `order_<id>`) within a
  // short window so the owner gets one banner, not three.
  static const Duration _kDedupWindow = Duration(seconds: 90);
  final Map<String, DateTime> _dedupKeyTimestamps = {};
  final Map<String, int> _dedupKeyLocalIds = {};

  bool _shouldSuppressDup(String dedupKey) {
    final ts = _dedupKeyTimestamps[dedupKey];
    if (ts == null) return false;
    if (DateTime.now().difference(ts) > _kDedupWindow) {
      _dedupKeyTimestamps.remove(dedupKey);
      _dedupKeyLocalIds.remove(dedupKey);
      return false;
    }
    return true;
  }

  // Map of remote notification keys (backend IDs or FCM messageIds) to the
  // local integer notification IDs created by the plugin. Used to cancel
  // specific delivered notifications when the user views them in-app.
  final Map<String, int> _remoteToLocal = {};

  Future<void> _restoreRemoteToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kRemoteToLocalPrefKey) ?? '';
      if (jsonStr.isNotEmpty) {
        final Map<String, dynamic> parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        _remoteToLocal.clear();
        parsed.forEach((k, v) {
          try {
            _remoteToLocal[k] = (v as num).toInt();
          } catch (_) {}
        });
        debugPrint('[NotificationService] Restored remote->local map (${_remoteToLocal.length} entries)');
      }
    } catch (e) {
      debugPrint('[NotificationService] _restoreRemoteToLocal error: $e');
    }
  }

  Future<void> _saveRemoteToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRemoteToLocalPrefKey, jsonEncode(_remoteToLocal));
    } catch (e) {
      debugPrint('[NotificationService] _saveRemoteToLocal error: $e');
    }
  }

  // ── In-app listeners ───────────────────────────────────────────────────────
  final List<NotificationListener> _listeners = [];

  // ── Public API: listeners ──────────────────────────────────────────────────

  void addListener(NotificationListener listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  // ── Lightweight analytics (prefs-backed counters) ───────────────────────
  Future<void> _logAnalyticsEvent(String name, Map<String, dynamic>? params) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name == 'notification_impression') {
        final cur = prefs.getInt(_kAnalyticsImpressions) ?? 0;
        await prefs.setInt(_kAnalyticsImpressions, cur + 1);
      } else if (name == 'notification_open') {
        final cur = prefs.getInt(_kAnalyticsOpens) ?? 0;
        await prefs.setInt(_kAnalyticsOpens, cur + 1);
      }
      debugPrint('[Analytics] $name params=$params');
    } catch (e) {
      debugPrint('[Analytics] log error: $e');
    }
  }

  Future<int> getAnalyticsImpressions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAnalyticsImpressions) ?? 0;
  }

  Future<int> getAnalyticsOpens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAnalyticsOpens) ?? 0;
  }

  // ── Streak helpers ─────────────────────────────────────────────────────
  Future<void> _incrementReminderStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(_kReminderLastOpenKey);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (last == today) return; // already counted today
      final cur = prefs.getInt(_kReminderStreakKey) ?? 0;
      await prefs.setInt(_kReminderStreakKey, cur + 1);
      await prefs.setString(_kReminderLastOpenKey, today);
      debugPrint('[Streak] incremented to ${cur + 1}');
    } catch (e) {
      debugPrint('[Streak] increment error: $e');
    }
  }

  Future<int> getReminderStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kReminderStreakKey) ?? 0;
  }

  // ── Adaptive timing helpers ───────────────────────────────────────────
  Future<void> _recordOpenAndAdapt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adaptive = prefs.getBool(_kAdaptiveEnabledKey) ?? true;
      if (!adaptive) return;

      // Load histogram
      final histJson = prefs.getString(_kOpenHistogramKey);
      List<int> hist = List.filled(24, 0);
      if (histJson != null && histJson.isNotEmpty) {
        final parsed = jsonDecode(histJson) as List<dynamic>;
        for (int i = 0; i < parsed.length && i < 24; i++) {
          hist[i] = (parsed[i] as num).toInt();
        }
      }

      final now = DateTime.now().toUtc();
      final hour = now.toLocal().hour; // use device local hour
      hist[hour] = hist[hour] + 1;
      await prefs.setString(_kOpenHistogramKey, jsonEncode(hist));

      // Compute preferred hour (simple argmax)
      int maxIdx = 0;
      for (int i = 1; i < 24; i++) {
        if (hist[i] > hist[maxIdx]) maxIdx = i;
      }

      // If preferred hour differs from stored reminder time by >=1 hour, update stored config and reschedule
      final cfg = await getDailyReminderConfig();
      final storedHour = cfg['hour'] ?? 12;
      if (maxIdx != storedHour) {
        final minute = cfg['minute'] ?? 0;
        // Save new preferred hour
        await prefs.setInt(_kDailyReminderHourKey, maxIdx);
        // Reschedule if reminders are enabled
        final enabled = prefs.getBool(_kDailyReminderEnabledKey) ?? false;
        if (enabled) {
          // Use existing window
          final window = prefs.getInt(_kDailyReminderWindowKey) ?? 30;
          // Reschedule with same id
          await scheduleDailyReminder(
            id: 9001,
            hour: maxIdx,
            minute: minute,
            windowMinutes: window,
            title: 'Today on CampusChow',
            body: 'Tap to see fresh picks and limited-time deals.',
            payload: null,
          );
        }
        debugPrint('[Adaptive] Adjusted preferred hour to $maxIdx from $storedHour');
      }
    } catch (e) {
      debugPrint('[Adaptive] record open error: $e');
    }
  }

  Future<bool> isAdaptiveEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAdaptiveEnabledKey) ?? true;
  }

  Future<void> setAdaptiveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdaptiveEnabledKey, enabled);
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
    // Restore persisted remote->local mapping so we can cancel specific
    // delivered notifications even after app restarts.
    await _restoreRemoteToLocal();
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

    final launchDetails = await _localPlugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    final payload = response?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.isNotEmpty) {
      debugPrint(
        '[NotificationService] App launched from local notification payload=$payload',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigate(type: null, id: payload);
      });
    }

    await _createAndroidChannels();
    // Ensure timezone data available for scheduled notifications
    try {
      tzdata.initializeTimeZones();
    } catch (e) {
      debugPrint('[NotificationService] Failed to initialize timezone database: $e');
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('[Notification] Tapped — payload=${response.payload}');
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      // Analytics: notification opened
      _logAnalyticsEvent('notification_open', {'payload': payload});
      if (payload.startsWith(_kReminderPayloadPrefix)) {
        _incrementReminderStreak();
        _recordOpenAndAdapt();
      }
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
        playSound: true,
        sound: RawResourceAndroidNotificationSound('order_sound'),
      ),
    );

    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        kGentleChannelId,
        'Daily Reminders',
        description: 'Gentle daily reminders',
        importance: Importance.low,
        playSound: false,
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
        // Defer to the next frame so the widget tree is fully mounted/resumed
        // before we attempt navigation. Without this, calling push() during
        // Activity resume on Android hits a partially-mounted Navigator and
        // causes a crash or a GoRouter assertion.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _onNotificationTap(msg),
        );
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
      final orderId = message.data['orderId'] ?? message.data['id'];
      final type = message.data['type']?.toString();
      final payload = type == 'new_order' && orderId != null
          ? 'store_order_$orderId'
          : orderId?.toString();
      await showNotification(
        title: n.title ?? 'New Notification',
        body: n.body ?? '',
        payload: payload,
        remoteId: message.data['id']?.toString() ?? id,
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
          remoteId: message.data['id']?.toString() ?? message.messageId,
          channelId: kHighImportanceChannelId,
        );

      case 'order_update':
      case 'order_processing':
      case 'price_adjusted':
      case 'priceadjusted':
      case 'price_adjustment':
        await showNotification(
          title: switch (type) {
            'order_processing' => 'Order Processing',
            'price_adjusted' ||
            'priceadjusted' ||
            'price_adjustment' => 'Order Price Updated',
            _ => 'Order Updated',
          },
          body:
              type == 'price_adjusted' ||
                  type == 'priceadjusted' ||
                  type == 'price_adjustment'
              ? 'The store owner updated your order price. Tap to review.'
              : status.isNotEmpty
              ? 'Your order status is now: ${status.replaceAll('_', ' ')}'
              : 'Your order is being processed.',
          payload: orderId,
          remoteId: message.data['id']?.toString() ?? message.messageId,
          channelId: kOrderChannelId,
        );

      case 'new_order':
        await showNotification(
          title: 'New Order Received!',
          body: 'A customer just placed a new order.',
          payload: orderId == null ? null : 'store_order_$orderId',
          remoteId: message.data['id']?.toString() ?? message.messageId,
          channelId: kOrderChannelId,
          // FIX (cross-source dedup): the same order may already have produced
          // a banner via Ably; collapse them to one.
          dedupKey: orderId == null ? null : 'order_$orderId',
        );

      case 'payment_success':
      case 'payment_alert':
        await showNotification(
          title: 'Payment Successful',
          body: 'Payment confirmed for order #$orderId',
          payload: orderId,
          remoteId: message.data['id']?.toString() ?? message.messageId,
        );
        break;
      default:
        debugPrint('[FCM] Unhandled data-only type: $type');
    }
  }

  // ── Notification tap ───────────────────────────────────────────────────────

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tap — data=${message.data}');
    // Analytics: notification opened (from FCM)
    _logAnalyticsEvent('notification_open', message.data);
    final payload = (message.data['orderId'] ?? message.data['id']) as String?;
    if (payload != null && payload.startsWith(_kReminderPayloadPrefix)) _incrementReminderStreak();
    _recordOpenAndAdapt();
    _navigate(
      type: message.data['type'] as String?,
      id: payload,
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigate({
    required String? type,
    required String? id,
    int attempt = 0,
  }) {
    debugPrint('[Notification] Navigate — type=$type, id=$id');

    // Drop reminder payloads entirely — they carry no orderId and routing them
    // to /order-details produces a FormatException from GoRouter's Uri parser
    // because the payload contains illegal characters (e.g. '|').
    if (id != null && id.startsWith(_kReminderPayloadPrefix)) {
      debugPrint('[Notification] Reminder payload — skipping navigation');
      return;
    }

    final navigatorState = rootNavigatorKey.currentState;
    final context = rootNavigatorKey.currentContext;

    if (context == null || navigatorState == null) {
      if (attempt < 15) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _navigate(type: type, id: id, attempt: attempt + 1);
        });
        return;
      }
      debugPrint(
        '[Notification] Navigation skipped after retries: navigator is null',
      );
      return;
    }

    // Resolve the clean order id from whatever format the payload uses.
    String? cleanId = id;
    bool isStoreOrder = false;
    if (cleanId != null && cleanId.startsWith('store_order_')) {
      cleanId = cleanId.replaceFirst('store_order_', '');
      isStoreOrder = true;
    } else if (cleanId != null && cleanId.startsWith('order_')) {
      cleanId = cleanId.replaceFirst('order_', '');
    }

    // Determine whether this app instance is acting as a store/admin context.
    // We detect this from the current GoRouter location rather than injecting
    // the AuthProvider, which may not be available in all call paths.
    //
    // IMPORTANT: Use maybeOf (not of) — on iOS cold-launch from a notification
    // tap, GoRouter's InheritedGoRouter widget may not have mounted yet even
    // after the navigator is ready.  GoRouter.of() in release mode throws a
    // null-check crash in that window.  We default to false (customer context)
    // so the fallback StoreOrderDetailScreen path still handles store orders.
    bool isStoreContext = false;
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        final currentLocation =
            router.routeInformationProvider.value.uri.path;
        isStoreContext =
            currentLocation.startsWith(routeStoreDashboard) ||
            currentLocation.startsWith(routeWorkerDashboard) ||
            currentLocation.startsWith(routeAdminDashboard);
      }
    } catch (_) {
      // GoRouter not yet reachable — treat as customer context.
    }

    // ── Deposit / wallet ─────────────────────────────────────────────────────
    if (type == 'deposit' || cleanId == 'wallet') {
      if (isStoreContext) {
        // Store owners are outside the tab shell; /profile/transactions is a
        // shell sub-route and cannot be pushed from outside the shell.
        // Use native Navigator to avoid GoRouter shell assertion.
        debugPrint('[Notification] Store context — skipping wallet navigation');
        return;
      }
      context.push(routeTransactions);
      return;
    }

    // ── Order-related ────────────────────────────────────────────────────────
    if (cleanId != null && cleanId.isNotEmpty) {
      if (isStoreOrder || type == 'new_order') {
        // Always use the native Navigator for store order screens to avoid
        // conflicts with GoRouter's shell routing.
        navigatorState.push(
          MaterialPageRoute(
            builder: (_) => StoreOrderDetailScreen(orderId: cleanId!),
          ),
        );
        return;
      }

      if (isStoreContext) {
        // Store / worker / admin — open as a native overlay screen so we don't
        // try to push a GoRouter customer shell route from outside the shell.
        navigatorState.push(
          MaterialPageRoute(
            builder: (_) => StoreOrderDetailScreen(orderId: cleanId!),
          ),
        );
        return;
      }

      // Customer context — safe to use GoRouter.
      try {
        context.push('/order-details/$cleanId');
      } catch (e) {
        debugPrint('[Notification] context.push failed: $e — retrying with Navigator');
        navigatorState.push(
          MaterialPageRoute(
            builder: (_) => StoreOrderDetailScreen(orderId: cleanId!),
          ),
        );
      }
      return;
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

  Future<int> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String? remoteId,
    String channelId = kHighImportanceChannelId,
    String? dedupKey,
  }) async {
    debugPrint(
      '[NotificationService] showNotification title=$title body=$body payload=$payload channelId=$channelId dedupKey=$dedupKey',
    );
    // FIX (cross-source dedup): if we've already posted a notification for
    // this dedupKey within the window, return the previous localId without
    // emitting another OS banner.
    if (dedupKey != null && _shouldSuppressDup(dedupKey)) {
      final existing = _dedupKeyLocalIds[dedupKey];
      debugPrint(
        '[NotificationService] suppressed duplicate for dedupKey=$dedupKey (existing localId=$existing)',
      );
      return existing ?? -1;
    }
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

    final localId = (id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF;
    await _localPlugin.show(
      id: localId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );

    if (remoteId != null && remoteId.isNotEmpty) {
      try {
        _remoteToLocal[remoteId] = localId;
        await _saveRemoteToLocal();
      } catch (_) {}
    }
    // FIX (cross-source dedup): record the timestamp + localId so subsequent
    // calls within the window are suppressed and can be cancelled together.
    if (dedupKey != null) {
      _dedupKeyTimestamps[dedupKey] = DateTime.now();
      _dedupKeyLocalIds[dedupKey] = localId;
    }
    // Analytics: count impression for gentle reminders
    if (channelId == kGentleChannelId) {
      _logAnalyticsEvent('notification_impression', {'channel': channelId, 'payload': payload});
    }
    debugPrint('[NotificationService] Local notification posted successfully id=$localId remoteId=$remoteId');
    return localId;
  }

  /// Cancel a local notification that corresponds to a remote key (backend
  /// notification id or FCM message id) if we previously stored a mapping.
  Future<void> cancelLocalForRemote(String remoteKey) async {
    try {
      final id = _remoteToLocal[remoteKey];
      if (id != null) {
        await _localPlugin.cancel(id: id);
        _remoteToLocal.remove(remoteKey);
        await _saveRemoteToLocal();
        debugPrint('[NotificationService] Canceled local notification id=$id for remoteKey=$remoteKey');
      }
    } catch (e) {
      debugPrint('[NotificationService] cancelLocalForRemote error: $e');
    }
  }

  /// Clear application icon badge (iOS/Android) if supported.
  Future<void> clearAppBadge() async {
    try {
      if (await FlutterAppBadger.isAppBadgeSupported()) {
        FlutterAppBadger.removeBadge();
        debugPrint('[NotificationService] Cleared app badge');
      }
    } catch (e) {
      debugPrint('[NotificationService] clearAppBadge error: $e');
    }
  }

  Future<void> setAppBadgeCount(int count) async {
    try {
      if (!(await FlutterAppBadger.isAppBadgeSupported())) return;
      if (count > 0) {
        // Use dynamic invocation to handle variations in plugin API names.
        final appBadger = FlutterAppBadger;
        try {
          (appBadger as dynamic).updateBadge(count);
        } catch (_) {
          try {
            (appBadger as dynamic).updateBadgeCount(count);
          } catch (e) {
            debugPrint('[NotificationService] updateBadge method not available: $e');
          }
        }
      } else {
        FlutterAppBadger.removeBadge();
      }
      debugPrint('[NotificationService] setAppBadgeCount=$count');
    } catch (e) {
      debugPrint('[NotificationService] setAppBadgeCount error: $e');
    }
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
        kOrderChannelId,
        'Order Notifications',
        channelDescription: 'CampusChow notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('order_sound'),
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

  // ── Gentle daily reminders (non-intrusive) ──────────────────────────────

  Future<void> scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    int windowMinutes = 30,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDailyReminderEnabledKey, true);
      await prefs.setInt(_kDailyReminderHourKey, hour);
      await prefs.setInt(_kDailyReminderMinuteKey, minute);
      await prefs.setInt(_kDailyReminderWindowKey, windowMinutes);

      final rand = Random();
      final offset = rand.nextInt(windowMinutes + 1);
      final scheduledMinute = minute + offset;

      final scheduled = _nextInstanceOfTime(hour, scheduledMinute);
      // Choose a template matching the scheduled hour slot (morning/afternoon/evening/late_night/any)
      final slot = _slotForHour(hour);
      final candidates = <Map<String, dynamic>>[];
      for (final t in _reminderTemplates) {
        final slots = (t['slots'] as List<dynamic>).cast<String>();
        if (slots.contains('any') || slots.contains(slot)) candidates.add(t);
      }
      final chosen = candidates.isNotEmpty ? candidates[rand.nextInt(candidates.length)] : _reminderTemplates[rand.nextInt(_reminderTemplates.length)];
      final tmplIdx = _reminderTemplates.indexOf(chosen);
      final finalTitle = chosen['title'] as String;
      final finalBody = chosen['body'] as String;
      final finalPayload = '$_kReminderPayloadPrefix|t$tmplIdx';

      final androidDetails = AndroidNotificationDetails(
        kGentleChannelId,
        'Daily Reminders',
        channelDescription: 'Gentle daily nudges',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
      );
      final iosDetails = DarwinNotificationDetails(presentSound: false);

      await _localPlugin.zonedSchedule(
        id: id,
        title: finalTitle,
        body: finalBody,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: finalPayload,
      );
      debugPrint('[NotificationService] Scheduled daily reminder id=$id at $hour:$minute ±$windowMinutes');
      // Analytics: scheduled == impression for our lightweight metric
      _logAnalyticsEvent('notification_impression', {'scheduled_at': scheduled.toString(), 'id': id, 'payload': finalPayload, 'template': tmplIdx});
    } catch (e) {
      debugPrint('[NotificationService] scheduleDailyReminder error: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await _localPlugin.cancel(id: id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDailyReminderEnabledKey, false);
      debugPrint('[NotificationService] Cancelled reminder id=$id');
    } catch (e) {
      debugPrint('[NotificationService] cancelReminder error: $e');
    }
  }

  /// Cancel local notifications and remove delivered notifications from
  /// the OS notification center (iOS). If [all] is true, cancels all local
  /// notifications; otherwise attempts to cancel by provided [ids] and
  /// falls back to clearing delivered notifications.
  Future<void> clearDeliveredNotifications({List<int>? ids, bool all = false}) async {
    try {
      if (all) {
        await _localPlugin.cancelAll();
        _remoteToLocal.clear();
        await _saveRemoteToLocal();
      } else if (ids != null && ids.isNotEmpty) {
        for (final id in ids) {
          await _localPlugin.cancel(id: id);
        }
      } else {
        await _localPlugin.cancelAll();
        _remoteToLocal.clear();
        await _saveRemoteToLocal();
      }

        // CancelAll removes local notifications posted by this plugin. Some
        // platforms may still require platform-specific delivered-notification
        // removal, but calling `cancelAll` addresses the common cases.
      debugPrint('[NotificationService] Cleared delivered notifications (all=$all)');
    } catch (e) {
      debugPrint('[NotificationService] clearDeliveredNotifications error: $e');
    }
  }

  Future<void> snoozeReminder({required int id, required int minutes}) async {
    try {
      final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
      final androidDetails = AndroidNotificationDetails(
        kGentleChannelId,
        'Daily Reminders',
        channelDescription: 'Gentle daily nudges',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
      );
      final iosDetails = DarwinNotificationDetails(presentSound: false);
      await _localPlugin.zonedSchedule(
        id: id,
        title: 'Reminder',
        body: 'Snoozed reminder',
        scheduledDate: when,
        notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: null,
      );
    } catch (e) {
      debugPrint('[NotificationService] snoozeReminder error: $e');
    }
  }

  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyReminderEnabledKey) ?? false;
  }

  Future<Map<String, int>> getDailyReminderConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hour': prefs.getInt(_kDailyReminderHourKey) ?? 12,
      'minute': prefs.getInt(_kDailyReminderMinuteKey) ?? 0,
      'window': prefs.getInt(_kDailyReminderWindowKey) ?? 30,
    };
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Singleton accessor
// ─────────────────────────────────────────────────────────────────────────────

final notificationService = NotificationService();
