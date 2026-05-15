import 'package:campuschow/models/notification_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notifications/clear_notifications_dialog.dart';
import '../widgets/notifications/empty_notifications.dart';
import '../widgets/notifications/notifications_app_bar.dart';
import '../widgets/notifications/notifications_list.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<NotificationProvider, List<NotificationItem>>(
      selector: (context, provider) => provider.notifications,
      builder: (context, notifications, _) {
        return Scaffold(
          appBar: NotificationsAppBar(
            hasNotifications: notifications.isNotEmpty,
            onClearAll: () => _showClearConfirmation(
              context,
              context.read<NotificationProvider>(),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<NotificationProvider>().refresh(),
            child: notifications.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: const EmptyNotifications(),
                      ),
                    ],
                  )
                : NotificationsList(notifications: notifications),
          ),
        );
      },
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
