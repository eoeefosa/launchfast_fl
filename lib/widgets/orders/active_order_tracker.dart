import 'package:flutter/material.dart';
import 'package:campuschow/widgets/orders/active_order_tracker/rider_card.dart';
import 'package:campuschow/widgets/orders/active_order_tracker/status_icons.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/order.dart';
import '../../constants/app_colors.dart';
import 'order_timeline.dart';
import 'pickup_qr_card.dart';

class ActiveOrderTracker extends StatelessWidget {
  final Order order;

  const ActiveOrderTracker({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final statusText = _getStatusText(order.status);
    final statusDescription = _getStatusDescription(order.status);

    final rider = order.rider;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'ORDER #${order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              statusDescription,
                              style: TextStyle(
                                color: AppColors.lightMuted,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusIcon(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 40),
                  OrderTimeline(order: order),
                ],
              ),
            ),
            if (rider != null) RiderCard(rider: rider, isIOS: isIOS),

            // ── Pickup QR ──────────────────────────────────────────────
            // Show the QR code card when the order is a pickup and ready.
            if (_isPickup(order.deliveryType))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: PickupQrCard(orderId: order.id),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  String _getStatusText(OrderStatus status) {
    final isPickup = _isPickup(order.deliveryType);
    switch (status) {
      case OrderStatus.queued:
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.priceAdjusted:
        return 'Price Adjustment';
      case OrderStatus.accepted:
        return 'Order Accepted';
      case OrderStatus.preparing:
        return 'Preparing Meal';
      case OrderStatus.readyForPickup:
        return isPickup ? 'Ready for Pickup' : 'Ready for Delivery';
      case OrderStatus.pickingUp:
        return 'Picking Up';
      case OrderStatus.onTheWay:
      case OrderStatus.outForDelivery:
        return 'On the Way';
      case OrderStatus.delivered:
        return isPickup ? 'Picked Up' : 'Arrived';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.pendingPayment:
        return 'Pending Payment';
    }
  }

  String _getStatusDescription(OrderStatus status) {
    final isPickup = _isPickup(order.deliveryType);
    switch (status) {
      case OrderStatus.queued:
      case OrderStatus.pending:
        return 'We are confirming your order with the store.';
      case OrderStatus.priceAdjusted:
        return 'The store has updated the prices for this order. Please accept the new price to proceed.';
      case OrderStatus.accepted:
        return 'The store has accepted your order and will start soon.';
      case OrderStatus.preparing:
        return 'Your chef is working their magic right now.';
      case OrderStatus.readyForPickup:
        return isPickup
            ? 'Your meal is ready! Please come pick it up.'
            : 'Your meal is ready and waiting for a rider.';
      case OrderStatus.pickingUp:
        return 'A rider is picking up your order from the store.';
      case OrderStatus.onTheWay:
      case OrderStatus.outForDelivery:
        return 'Hang tight! Your food is being delivered.';
      case OrderStatus.delivered:
        return isPickup
            ? 'Hope you enjoyed your meal!'
            : 'Enjoy your delicious meal!';
      case OrderStatus.cancelled:
        if (order.rejectionReason != null &&
            order.rejectionReason!.isNotEmpty) {
          return 'This order was cancelled. Reason: ${order.rejectionReason}';
        }
        return 'This order was cancelled. Please contact support for details.';
      case OrderStatus.pendingPayment:
        return 'Please complete the payment to place your order.';
    }
  }

  /// True for any pickup/store-collection delivery type.
  bool _isPickup(String deliveryType) {
    final t = deliveryType.toLowerCase();
    return t == 'pickup' || t == 'store_pickup' || t == 'storепickup';
  }
}
