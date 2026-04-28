import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import 'notification_tile.dart';

class NotificationsList extends StatelessWidget {
  const NotificationsList({super.key, required this.notifications});

  final List<NotificationItem> notifications;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Implementation for refresh if needed
      },
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (_, index) => NotificationTile(item: notifications[index]),
      ),
    );
  }
}
