import 'package:flutter/material.dart';
import 'package:campuschow/models/notification_item.dart';

/// Routes notifications to the correct application flow.
/// Handles Rider, Store, and User navigation roles.
class NotificationRouter {
  static void handleNotificationTap(BuildContext context, NotificationItem item) {
    final metadata = item.metadata;
    if (metadata == null) {
      debugPrint('[NotificationRouter] No metadata for ${item.id}');
      return;
    }

    final type = metadata['type']?.toString();
    final orderId = metadata['orderId']?.toString() ?? metadata['id']?.toString();

    if (orderId == null) {
      debugPrint('[NotificationRouter] Missing orderId for ${item.title}');
      return;
    }

    // Handle Role-based Routing
    switch (type) {
      // Rider Workflows
      case 'new_job':
      case 'job_accepted':
        Navigator.of(context).pushNamed('/rider/orders/detail', arguments: orderId);
        break;

      // Store Owner Workflows
      case 'new_order':
        Navigator.of(context).pushNamed('/store/orders/detail', arguments: orderId);
        break;

      // Shared Status Updates
      case 'order_processing':
      case 'order_ready':
      case 'delivery_update':
        _routeByRole(context, orderId, metadata['role']?.toString());
        break;

      default:
        debugPrint('[NotificationRouter] Unhandled notification type: $type');
        // Default to a detail view if available
        Navigator.of(context).pushNamed('/notifications/detail', arguments: item.id);
    }
  }

  static void _routeByRole(BuildContext context, String orderId, String? role) {
    switch (role) {
      case 'rider':
        Navigator.of(context).pushNamed('/rider/orders/detail', arguments: orderId);
        break;
      case 'store':
        Navigator.of(context).pushNamed('/store/orders/detail', arguments: orderId);
        break;
      default:
        Navigator.of(context).pushNamed('/orders/detail', arguments: orderId);
    }
  }
}
