import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'package:campuschow/store/lib/core/network/api_client.dart';
import 'package:campuschow/models/notification_entity.dart';
import '../locator.dart';
import '../models/notification_item.dart';
import '../services/ably_service.dart';

class NotificationProvider with ChangeNotifier {

  NotificationProvider({
    // FIX #3 — injected dependencies, not globals
    ApiService? apiService,
    AblyService? ablyService,
  })  : _apiService = apiService ?? locator<ApiService>(),
        _ablyService = ablyService ?? locator<AblyService>();

  // ─────────────────────────────────────────────────────────────
  // Dependencies
  // ─────────────────────────────────────────────────────────────

  final ApiService  _apiService;
  final AblyService _ablyService;

  // ─────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────

  late Box<NotificationEntity> _box;
  List<NotificationItem> _notifications = [];
  bool _isLoading          = false;
  bool _initialized        = false;
  bool _disposed           = false;
  bool _refreshInProgress  = false;
  Timer? _pendingRefreshTimer;

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading   => _isLoading;
  int  get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ─────────────────────────────────────────────────────────────
  // FIX #1 — explicit initialize() instead of async work in constructor.
  // Call this from your widget tree (e.g. in main.dart after provider setup).
  // ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Hive must succeed before anything else accesses _box.
      await _initHive();
      await refresh();
      _initListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationProvider] initialize error: $e');
    } finally {
      _initialized = true;
    }
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NotificationEntityAdapter());
    }
    _box = await Hive.openBox<NotificationEntity>('notifications');
  }

  void _initListeners() {
    _ablyService.addNotificationListener((payload) {
      _processPayload(payload);
      _scheduleDelayedRefresh();
    });

    notificationService.addListener((payload) {
      _processPayload(payload);
      _scheduleDelayedRefresh();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Real-time helpers
  // ─────────────────────────────────────────────────────────────

  /// Debounced backend sync so rapid real-time events cause only one refresh.
  void _scheduleDelayedRefresh() {
    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = Timer(const Duration(seconds: 3), () {
      if (kDebugMode) debugPrint('[NotificationProvider] Delayed refresh triggered');
      refresh();
    });
  }

  void _processPayload(Map<String, dynamic> payload) {
    // FIX #4 — no raw payload in production logs
    if (kDebugMode) debugPrint('[NotificationProvider] Real-time payload received');

    final notification = NotificationItem(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: payload['title'] ?? 'New Update',
      message: payload['body'] ?? payload['message'] ?? '',
      type: _parseNotificationType(payload['type']?.toString()),
      timestamp: DateTime.now(),
      metadata: payload,
    );
    _saveLocalOnly(notification);
  }

  // ─────────────────────────────────────────────────────────────
  // Local save
  // FIX #5 — ID-based deduplication instead of fragile title + time window
  // ─────────────────────────────────────────────────────────────

  Future<void> _saveLocalOnly(NotificationItem item) async {
    // A real (non-temp) notification with this ID already exists — skip.
    final isDuplicate = _notifications.any(
      (n) => !n.id.startsWith('temp_') && n.id == item.id,
    );
    if (isDuplicate) return;

    final entity = NotificationEntity()
      ..notificationId = item.id
      ..title          = item.title
      ..message        = item.message
      ..type           = item.type.name
      ..timestamp      = item.timestamp
      ..isRead         = item.isRead
      ..metadata       = item.metadata != null ? jsonEncode(item.metadata) : null;

    await _box.add(entity);
    _notifications.insert(0, item);
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Refresh
  // FIX #9 — guard against concurrent calls with _refreshInProgress flag
  // ─────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    _isLoading = true;
    _safeNotify();

    try {
      // Show local cache first for instant display
      _notifications = _boxToList();
      _safeNotify();

      if (kDebugMode) debugPrint('[NotificationProvider] Syncing with backend...');

      final response = await _apiService.dio.get('/notifications');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        if (kDebugMode) {
          debugPrint('[NotificationProvider] Received ${data.length} notifications');
        }

        final backendEntities = data.map((item) {
          final backendId    = item['_id']?.toString() ?? '';
          final backendTitle = item['title'] ?? '';
          final backendBody  = item['body'] ?? '';

          // Preserve read state for entries that were marked locally
          // before the backend confirmed the update.
          final isLocallyRead = _notifications.any((n) =>
            n.isRead &&
            (n.id == backendId ||
              (n.id.startsWith('temp_') &&
               n.title == backendTitle &&
               n.message == backendBody)));

          final bool finalIsRead = (item['isRead'] == true) || isLocallyRead;

          // FIX #2 — named method replaces the silent inline async IIFE
          if (isLocallyRead && item['isRead'] != true && backendId.isNotEmpty) {
            _pushReadStatusToBackend(backendId);
          }

          return NotificationEntity()
            ..notificationId = backendId
            ..title          = backendTitle
            ..message        = backendBody
            ..type           = item['type'] ?? 'serverAlert'
            ..timestamp      = item['createdAt'] != null
                ? DateTime.parse(item['createdAt'])
                : DateTime.now()
            ..isRead         = finalIsRead
            ..metadata       = item['data'] != null
                ? jsonEncode(item['data'])
                : null;
        }).toList();

        await _box.clear();
        if (backendEntities.isNotEmpty) {
          await _box.addAll(backendEntities);
        }

        _notifications = _boxToList();

        if (kDebugMode) {
          debugPrint('[NotificationProvider] Synced ${_notifications.length} notifications');
        }
      }
    } catch (e) {
      // Non-fatal — local cache is still displayed
      if (kDebugMode) {
        debugPrint('[NotificationProvider] Backend sync failed (using cache): $e');
      }
    } finally {
      _refreshInProgress = false;
      _isLoading = false;
      _safeNotify();
    }
  }

  // FIX #2 — extracted from the silent inline IIFE in the original code
  Future<void> _pushReadStatusToBackend(String notificationId) async {
    try {
      await _apiService.dio.patch(
        '/notifications',
        data: {'notificationId': notificationId},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationProvider] _pushReadStatusToBackend failed: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Box → list
  // ─────────────────────────────────────────────────────────────

  List<NotificationItem> _boxToList() {
    return _box.values
        .map((e) => NotificationItem.fromMap({
              'id':        e.notificationId,
              'title':     e.title,
              'message':   e.message,
              'type':      e.type,
              'timestamp': e.timestamp.toIso8601String(),
              'isRead':    e.isRead,
              'metadata':  e.metadata != null ? jsonDecode(e.metadata!) : null,
            }))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ─────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────

  Future<void> addNotification(NotificationItem item) => _saveLocalOnly(item);

  Future<void> markAsRead(String id) async {
    // Update Hive
    final hiveIndex = _box.values
        .toList()
        .indexWhere((e) => e.notificationId == id);
    if (hiveIndex != -1) {
      final entity = _box.getAt(hiveIndex)!;
      entity.isRead = true;
      await entity.save();
    }

    // Update in-memory list
    final listIndex = _notifications.indexWhere((n) => n.id == id);
    if (listIndex != -1) {
      _notifications[listIndex] =
          _notifications[listIndex].copyWith(isRead: true);
      _safeNotify();
    }

    await _pushReadStatusToBackend(id);
  }

  // FIX #6 — markAllAsRead now syncs with backend
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _box.length; i++) {
      final entity = _box.getAt(i)!;
      entity.isRead = true;
      await entity.save();
    }
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _safeNotify();

    try {
      // Use a bulk endpoint if available; fall back to the single-mark route.
      await _apiService.dio.patch('/notifications/read-all');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationProvider] markAllAsRead backend sync failed: $e');
      }
    }
  }

  Future<void> removeNotification(String id) async {
    final index = _box.values
        .toList()
        .indexWhere((e) => e.notificationId == id);
    if (index != -1) await _box.deleteAt(index);

    _notifications.removeWhere((n) => n.id == id);
    _safeNotify();

    try {
      if (!id.startsWith('temp_')) {
        await _apiService.dio.delete('/notifications?notificationId=$id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationProvider] removeNotification backend failed: $e');
      }
    }
  }

  // FIX #7 — backend cleared first; local state only wiped on success
  Future<void> clearAll() async {
    try {
      await _apiService.dio.delete('/notifications');
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationProvider] clearAll backend failed: $e');
      rethrow; // Local cache preserved when backend call fails
    }

    await _box.clear();
    _notifications.clear();
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Type parsing
  // ─────────────────────────────────────────────────────────────

  NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.serverAlert;

    final normalized = type.toLowerCase();

    if (normalized == 'deposit'       ||
        normalized == 'walletupdate'  ||
        normalized == 'wallet_update' ||
        normalized == 'wallet_topup') {
      return NotificationType.walletUpdate;
    }

    if (normalized == 'order_update' || normalized == 'orderupdate') {
      return NotificationType.orderUpdate;
    }

    return NotificationType.values.firstWhere(
      (t) => t.name.toLowerCase() == normalized,
      orElse: () => NotificationType.serverAlert,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Safe notify
  // ─────────────────────────────────────────────────────────────

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    _pendingRefreshTimer?.cancel();
    super.dispose();
  }
}