import 'package:flutter/material.dart';
import 'package:campuschow/widgets/orders/active_order_tracker/rider_card.dart';
import 'package:campuschow/widgets/orders/active_order_tracker/status_icons.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/order.dart';
import '../../constants/app_colors.dart';
import 'order_timeline.dart';

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
                  OrderTimeline(status: order.status),
                ],
              ),
            ),
            if (rider != null) RiderCard(rider: rider, isIOS: isIOS),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.queued:
        return 'Pending Approval';
      case OrderStatus.preparing:
        return 'Preparing Meal';
      case OrderStatus.outForDelivery:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Arrived';
      default:
        return 'Order Placed';
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.queued:
        return 'We are confirming your order with the store.';
      case OrderStatus.preparing:
        return 'Your chef is working their magic right now.';
      case OrderStatus.outForDelivery:
        return 'Hang tight! Your food is being delivered.';
      case OrderStatus.delivered:
        return 'Enjoy your delicious meal!';
      default:
        return 'Processing your order...';
    }
  }
}
