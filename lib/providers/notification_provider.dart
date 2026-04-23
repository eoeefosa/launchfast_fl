import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString('user_notifications');
      if (notificationsJson != null) {
        final List<dynamic> decodedList = jsonDecode(notificationsJson);
        _notifications = decodedList
            .map((item) => NotificationItem.fromMap(item))
            .toList();
        // Sort by newest first
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedList = jsonEncode(
        _notifications.map((n) => n.toMap()).toList(),
      );
      await prefs.setString('user_notifications', encodedList);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> addNotification(NotificationItem item) async {
    _notifications.insert(0, item);
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveNotifications();
  }
}
