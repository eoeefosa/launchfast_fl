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
    ablyService.addNotificationListener((payload) => _processPayload(payload));
    notificationService.addListener((payload) => _processPayload(payload));
  }

  void _processPayload(Map<String, dynamic> payload) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: payload['title'] ?? 'New Update',
      message: payload['body'] ?? payload['message'] ?? '',
      type: _parseNotificationType(payload['type']?.toString()),
      timestamp: DateTime.now(),
      metadata: payload,
    );
    addNotification(notification);
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Local
      _notifications = _box.values
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
      notifyListeners();

      // 2. Remote
      try {
        debugPrint('🚀 [NotificationProvider] Syncing with backend...');
        final response = await apiService.dio.get('/notifications');
        debugPrint('✅ [NotificationProvider] Backend response: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          debugPrint('📬 [NotificationProvider] Received ${data.length} notifications from backend');
          
          await _box.clear();
          for (var item in data) {
            final entity = NotificationEntity()
              ..notificationId = item['_id']?.toString() ?? ''
              ..title = item['title'] ?? ''
              ..message = item['body'] ?? ''
              ..type = item['type'] ?? 'serverAlert'
              ..timestamp = item['createdAt'] != null 
                  ? DateTime.parse(item['createdAt']) 
                  : DateTime.now()
              ..isRead = item['isRead'] ?? false
              ..metadata = item['data'] != null ? jsonEncode(item['data']) : null;
            await _box.add(entity);
          }

          _notifications = _box.values
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
          
          debugPrint('✨ [NotificationProvider] Local cache updated with ${_notifications.length} items');
        }
      } catch (e) {
        debugPrint('❌ [NotificationProvider] Sync with backend failed: $e');
      }
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNotifications() async => refresh();

  Future<void> addNotification(NotificationItem item) async {
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
  }

  Future<void> clearAll() async {
    await _box.clear();
    _notifications.clear();
    notifyListeners();
    try {
      await apiService.dio.patch('/notifications', data: {});
    } catch (e) {
      debugPrint('Backend clearAll failed: $e');
    }
  }

  NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.serverAlert;
    try {
      return NotificationType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => NotificationType.serverAlert,
      );
    } catch (_) {
      return NotificationType.serverAlert;
    }
  }
}
