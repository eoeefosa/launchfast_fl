import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campuschow/models/notification_item.dart';
import 'package:campuschow/widgets/notifications/notification_detail_sheet.dart';

/// Routes notifications to the correct application flow.
/// Handles Rider, Store, and User navigation roles.
class NotificationRouter {
  static void handleNotificationTap(BuildContext context, NotificationItem item) {
    final metadata = item.metadata;
    final type = (metadata?['type']?.toString() ?? item.type.name).toLowerCase();
    final orderId = metadata?['orderId']?.toString() ?? 
                    metadata?['order_id']?.toString() ?? 
                    metadata?['id']?.toString();

    debugPrint('[NotificationRouter] Handling tap: type=$type, orderId=$orderId');

    // 1. Handle Wallet / Deposit Workflows - Show premium detail sheet
    if (type == 'deposit' || type == 'wallet_topup' || type == 'wallet_update' || item.type == NotificationType.walletUpdate) {
      NotificationDetailSheet.show(context, item);
      return;
    }

    // 2. Handle Order Workflows (if orderId is present)
    if (orderId != null) {
      switch (type) {
        case 'new_job':
        case 'job_accepted':
          context.push('/rider/orders/detail', extra: orderId);
          break;

        case 'new_order':
          context.push('/store/orders/detail', extra: orderId);
          break;

        case 'order_processing':
        case 'order_ready':
        case 'delivery_update':
        case 'order_update':
        case 'orderupdate':
          _routeByRole(context, orderId, metadata?['role']?.toString());
          break;

        default:
          context.push('/order-details/$orderId');
      }
      return;
    }

    // 3. Fallback: Just show the detail sheet for any other notification
    NotificationDetailSheet.show(context, item);
  }

  static void _routeByRole(BuildContext context, String orderId, String? role) {
    switch (role) {
      case 'rider':
        context.push('/rider/orders/detail', extra: orderId);
        break;
      case 'store':
        context.push('/store/orders/detail', extra: orderId);
        break;
      default:
        context.push('/order-details/$orderId');
    }
  }
}
