import 'dart:async';
import 'package:flutter/material.dart';
import 'package:campuschow/store/pages/core/services/notification_service.dart';
import 'package:campuschow/store/pages/core/models/notification_model.dart';
import 'package:campuschow/store/pages/core/network/api_client.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  Timer? _pendingRefreshTimer;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
    _initListeners();
  }

  void _initListeners() {
    notificationService.addListener((payload) {
      final notification = NotificationItem(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: payload['title'] ?? 'New Update',
        message: payload['body'] ?? payload['message'] ?? '',
        type: _parseNotificationType(payload['type']?.toString()),
        timestamp: DateTime.now(),
        metadata: payload,
      );
      addNotification(notification);
      _scheduleDelayedRefresh();
    });
  }

  void _scheduleDelayedRefresh() {
    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = Timer(const Duration(seconds: 3), () {
      refresh();
    });
  }

  NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.serverAlert;
    final cleanType = type.replaceAll('_', '').replaceAll('-', '').toLowerCase();

    // Map new_order or store_alert to orderUpdate
    if (cleanType == 'neworder' || cleanType == 'storealert') {
      return NotificationType.orderUpdate;
    }

    try {
      return NotificationType.values.firstWhere(
        (t) => t.name.toLowerCase() == cleanType,
        orElse: () => NotificationType.serverAlert,
      );
    } catch (_) {
      return NotificationType.serverAlert;
    }
  }

  Future<void> _loadNotifications() async => refresh();

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.dio.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        
        final backendEntities = data.map((item) {
          final backendId = item['_id']?.toString() ?? '';
          final backendTitle = item['title'] ?? '';
          final backendBody = item['body'] ?? '';

          final isLocallyRead = _notifications.any((n) => 
               n.isRead && (n.id == backendId || (n.id.startsWith('temp_') && n.title == backendTitle && n.message == backendBody))
          );
          
          final bool finalIsRead = (item['isRead'] == true) || isLocallyRead;
          
          if (isLocallyRead && item['isRead'] != true && backendId.isNotEmpty) {
             () async {
               try {
                 await apiService.dio.patch('/notifications', data: {'notificationId': backendId});
               } catch (_) {}
             }();
          }

          return NotificationItem(
            id: backendId,
            title: backendTitle,
            message: backendBody,
            type: _parseNotificationType(item['type']?.toString()),
            timestamp: item['createdAt'] != null ? DateTime.parse(item['createdAt']) : DateTime.now(),
            isRead: finalIsRead,
            metadata: item['data'],
          );
        }).toList();

        _notifications = backendEntities;
          notifyListeners();
          try {
            await notificationService.setAppBadgeCount(unreadCount);
          } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error loading store notifications from backend: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotification(NotificationItem item) async {
    _notifications.insert(0, item);
    notifyListeners();
    try {
      await notificationService.setAppBadgeCount(unreadCount);
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      try {
        await notificationService.setAppBadgeCount(unreadCount);
      } catch (_) {}
    }
    try {
      await apiService.dio.patch('/notifications', data: {'notificationId': id});
      // Cancel the matching local notification (if any) and update badge
      try {
        await notificationService.cancelLocalForRemote(id);
        await notificationService.setAppBadgeCount(unreadCount);
      } catch (_) {}
    } catch (e) {
      debugPrint('Backend markAsRead failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
    try {
      await apiService.dio.patch('/notifications');
      try {
        await notificationService.clearDeliveredNotifications(all: true);
        await notificationService.setAppBadgeCount(unreadCount);
      } catch (_) {}
    } catch (e) {
      debugPrint('Backend markAllAsRead failed: $e');
    }
  }

  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await notificationService.setAppBadgeCount(unreadCount);
    } catch (_) {}
    try {
      if (!id.startsWith('temp_')) {
        await apiService.dio.delete('/notifications?notificationId=$id');
      }
      try {
        await notificationService.cancelLocalForRemote(id);
        await notificationService.setAppBadgeCount(unreadCount);
      } catch (_) {}
    } catch (e) {
      debugPrint('Backend removeNotification failed: $e');
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    try {
      await apiService.dio.delete('/notifications');
      try {
        await notificationService.clearDeliveredNotifications(all: true);
        await notificationService.setAppBadgeCount(unreadCount);
      } catch (_) {}
    } catch (e) {
      debugPrint('Backend clearAll failed: $e');
    }
  }

  @override
  void dispose() {
    _pendingRefreshTimer?.cancel();
    super.dispose();
  }
}
