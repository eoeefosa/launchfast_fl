import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'package:campuschow/store/lib/core/network/api_client.dart';
import 'package:campuschow/models/notification_entity.dart';
import '../models/notification_item.dart';
import '../services/ably_service.dart';

class NotificationProvider with ChangeNotifier {
  late Box<NotificationEntity> _box;
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  Timer? _pendingRefreshTimer;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _initHive().then((_) {
      _loadNotifications();
      _initListeners();
    });
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NotificationEntityAdapter());
    }
    _box = await Hive.openBox<NotificationEntity>('notifications');
  }

  void _initListeners() {
    // When Ably or FCM fires a real-time notification:
    // 1. Save it locally immediately with a temp ID for instant UI update.
    // 2. Schedule a backend refresh after 3 seconds to replace the temp entry
    //    with the canonical MongoDB entry (and deduplicate).
    ablyService.addNotificationListener((payload) {
      _processPayload(payload);
      _scheduleDelayedRefresh();
    });

    notificationService.addListener((payload) {
      _processPayload(payload);
      _scheduleDelayedRefresh();
    });
  }

  /// Schedules a backend refresh 3 seconds after a real-time event.
  /// Debounced so rapid events only cause one refresh.
  void _scheduleDelayedRefresh() {
    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('⏱ [NotificationProvider] Delayed refresh triggered after real-time event');
      refresh();
    });
  }

  void _processPayload(Map<String, dynamic> payload) {
    debugPrint('📲 [NotificationProvider] Real-time payload received: $payload');
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

  /// Saves to local box without triggering a backend sync.
  Future<void> _saveLocalOnly(NotificationItem item) async {
    // Avoid duplicates by checking if a temp entry for this second already exists
    final isDuplicate = _notifications.any(
      (n) => n.title == item.title && 
             n.timestamp.difference(item.timestamp).inSeconds.abs() < 5,
    );
    if (isDuplicate) return;

    final entity = NotificationEntity()
      ..notificationId = item.id
      ..title = item.title
      ..message = item.message
      ..type = item.type.name
      ..timestamp = item.timestamp
      ..isRead = item.isRead
      ..metadata = item.metadata != null ? jsonEncode(item.metadata) : null;

    await _box.add(entity);
    _notifications.insert(0, item);
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load from local cache first for instant display
      _notifications = _boxToList();
      notifyListeners();

      // 2. Sync with backend (authoritative source of truth)
      try {
        debugPrint('🚀 [NotificationProvider] Syncing with backend...');
        final response = await apiService.dio.get('/notifications');
        debugPrint('✅ [NotificationProvider] Backend response: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          debugPrint('📬 [NotificationProvider] Received ${data.length} notifications from backend');
          
          // Backend is the source of truth — replace all local data with canonical entries.
          final backendEntities = data.map((item) {
            final backendId = item['_id']?.toString() ?? '';
            final backendTitle = item['title'] ?? '';
            final backendBody = item['body'] ?? '';
            
            // Match by exact ID or by title/body for temp notifications that haven't synced
            final isLocallyRead = _notifications.any((n) => 
               n.isRead && (n.id == backendId || (n.id.startsWith('temp_') && n.title == backendTitle && n.message == backendBody))
            );
            
            final bool finalIsRead = (item['isRead'] == true) || isLocallyRead;
            
            // If it's locally read but backend thinks it's unread, push the update to backend
            if (isLocallyRead && item['isRead'] != true && backendId.isNotEmpty) {
               () async {
                 try {
                   await apiService.dio.patch('/notifications', data: {'notificationId': backendId});
                 } catch (_) {}
               }();
            }

            final entity = NotificationEntity()
              ..notificationId = backendId
              ..title = backendTitle
              ..message = backendBody
              ..type = item['type'] ?? 'serverAlert'
              ..timestamp = item['createdAt'] != null 
                  ? DateTime.parse(item['createdAt']) 
                  : DateTime.now()
              ..isRead = finalIsRead
              ..metadata = item['data'] != null ? jsonEncode(item['data']) : null;
            return entity;
          }).toList();

          await _box.clear();
          if (backendEntities.isNotEmpty) {
            await _box.addAll(backendEntities);
          }
          
          _notifications = _boxToList();
          debugPrint('✨ [NotificationProvider] Synced ${_notifications.length} notifications');
        }
      } catch (e) {
        debugPrint('❌ [NotificationProvider] Backend sync failed (using local cache): $e');
      }
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<NotificationItem> _boxToList() {
    return _box.values
        .map((e) => NotificationItem.fromMap({
              'id': e.notificationId,
              'title': e.title,
              'message': e.message,
              'type': e.type,
              'timestamp': e.timestamp.toIso8601String(),
              'isRead': e.isRead,
              'metadata': e.metadata != null ? jsonDecode(e.metadata!) : null,
            }))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _loadNotifications() async => refresh();

  Future<void> addNotification(NotificationItem item) async {
    await _saveLocalOnly(item);
  }

  Future<void> markAsRead(String id) async {
    final index = _box.values.toList().indexWhere((e) => e.notificationId == id);
    if (index != -1) {
      final entity = _box.getAt(index)!;
      entity.isRead = true;
      await entity.save();
    }

    final nIndex = _notifications.indexWhere((n) => n.id == id);
    if (nIndex != -1) {
      _notifications[nIndex] = _notifications[nIndex].copyWith(isRead: true);
      notifyListeners();
    }

    try {
      await apiService.dio.patch('/notifications', data: {'notificationId': id});
    } catch (e) {
      debugPrint('Backend markAsRead failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _box.length; i++) {
      final entity = _box.getAt(i)!;
      entity.isRead = true;
      await entity.save();
    }
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  Future<void> removeNotification(String id) async {
    final index = _box.values.toList().indexWhere((e) => e.notificationId == id);
    if (index != -1) {
      await _box.deleteAt(index);
    }
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      if (!id.startsWith('temp_')) {
        await apiService.dio.delete('/notifications?notificationId=$id');
      }
    } catch (e) {
      debugPrint('Backend removeNotification failed: $e');
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
    _notifications.clear();
    notifyListeners();
    try {
      await apiService.dio.delete('/notifications');
    } catch (e) {
      debugPrint('Backend clearAll failed: $e');
    }
  }

  NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.serverAlert;
    // Normalize common backend type strings to enum names
    final normalized = type.toLowerCase();
    if (normalized == 'deposit' || 
        normalized == 'walletupdate' || 
        normalized == 'wallet_update' ||
        normalized == 'wallet_topup') {
      return NotificationType.walletUpdate;
    }
    if (normalized == 'order_update' || normalized == 'orderupdate') {
      return NotificationType.orderUpdate;
    }
    try {
      return NotificationType.values.firstWhere(
        (t) => t.name.toLowerCase() == normalized,
        orElse: () => NotificationType.serverAlert,
      );
    } catch (_) {
      return NotificationType.serverAlert;
    }
  }

  @override
  void dispose() {
    _pendingRefreshTimer?.cancel();
    super.dispose();
  }
}
