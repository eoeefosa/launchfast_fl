import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/notification_item.dart';
import '../../providers/notification_provider.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item});

  final NotificationItem item;

  void _handleTap(BuildContext context) {
    context.read<NotificationProvider>().markAsRead(item.id);

    switch (item.type) {
      case NotificationType.orderUpdate:
        context.go('/orders');
      case NotificationType.walletUpdate:
      case NotificationType.profileUpdate:
        context.go('/profile');
      case NotificationType.serverAlert:
      case NotificationType.promotion:
        // Optionally handle metadata URL if present
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: const _DismissBackground(),
      onDismissed: (_) =>
          context.read<NotificationProvider>().removeNotification(item.id),
      child: InkWell(
        onTap: () => _handleTap(context),
        child: _NotificationTileContent(item: item),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class _NotificationTileContent extends StatelessWidget {
  const _NotificationTileContent({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isRead ? null : Colors.blue.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(type: item.type),
          const SizedBox(width: 16),
          Expanded(child: _NotificationText(item: item)),
        ],
      ),
    );
  }
}

class _NotificationText extends StatelessWidget {
  const _NotificationText({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isRead ? FontWeight.bold : FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              DateFormat.jm().format(item.timestamp),
              style: TextStyle(fontSize: 12, color: mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type});

  final NotificationType type;

  static const _typeConfig = <NotificationType, (IconData, Color)>{
    NotificationType.orderUpdate: (Icons.delivery_dining, Colors.orange),
    NotificationType.walletUpdate: (Icons.account_balance_wallet, Colors.green),
    NotificationType.profileUpdate: (Icons.person, Colors.blue),
    NotificationType.serverAlert: (Icons.info, Colors.red),
    NotificationType.promotion: (Icons.local_offer, Colors.purple),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _typeConfig[type] ?? (Icons.notifications, Colors.grey);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
