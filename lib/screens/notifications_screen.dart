import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notifications/clear_notifications_dialog.dart';
import '../widgets/notifications/empty_notifications.dart';
import '../widgets/notifications/notifications_app_bar.dart';
import '../widgets/notifications/notifications_list.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      appBar: NotificationsAppBar(
        hasNotifications: notifications.isNotEmpty,
        onClearAll: () => _showClearConfirmation(context, provider),
      ),
      body: notifications.isEmpty
          ? const EmptyNotifications()
          : NotificationsList(notifications: notifications),
    );
  }

  static void _showClearConfirmation(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (_) => ClearNotificationsDialog(
        onConfirm: () {
          provider.clearAll();
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
