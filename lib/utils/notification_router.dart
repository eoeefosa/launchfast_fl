import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campuschow/models/notification_item.dart';
import 'package:campuschow/widgets/notifications/notification_detail_sheet.dart';
import 'package:campuschow/store/pages/features/dashboard/presentation/store_order_detail_screen.dart';
import 'package:campuschow/router.dart';

/// Routes notifications to the correct application flow.
/// Handles Rider, Store, and User navigation roles.
class NotificationRouter {
  static void handleNotificationTap(
    BuildContext context,
    NotificationItem item,
  ) {
    final metadata = item.metadata;
    final type = (metadata?['type']?.toString() ?? item.type.name)
        .toLowerCase();
    String? rawId =
        metadata?['orderId']?.toString() ??
        metadata?['order_id']?.toString() ??
        metadata?['id']?.toString();
    var isStoreOrderPayload = false;
    if (rawId != null && rawId.startsWith('store_order_')) {
      rawId = rawId.replaceFirst('store_order_', '');
      isStoreOrderPayload = true;
    } else if (rawId != null && rawId.startsWith('order_')) {
      rawId = rawId.replaceFirst('order_', '');
    }
    final orderId = rawId;

    debugPrint(
      '[NotificationRouter] Handling tap: type=$type, orderId=$orderId',
    );

    // 1. Handle Wallet / Deposit Workflows - Show premium detail sheet
    if (type == 'deposit' ||
        type == 'wallet_topup' ||
        type == 'wallet_update' ||
        item.type == NotificationType.walletUpdate) {
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
          // Store owner — push a native screen since the store dashboard
          // is outside the GoRouter shell.
          rootNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => StoreOrderDetailScreen(orderId: orderId),
            ),
          );
          break;

        case 'order_processing':
        case 'price_adjusted':
        case 'priceadjusted':
        case 'price_adjustment':
        case 'order_ready':
        case 'delivery_update':
        case 'order_update':
        case 'orderupdate':
          _routeByRole(context, orderId, metadata?['role']?.toString());
          break;

        default:
          if (isStoreOrderPayload) {
            rootNavigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => StoreOrderDetailScreen(orderId: orderId),
              ),
            );
            break;
          }
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
        // Use native Navigator for store — no GoRouter shell route exists.
        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => StoreOrderDetailScreen(orderId: orderId),
          ),
        );
        break;
      default:
        context.push('/order-details/$orderId');
    }
  }
}
