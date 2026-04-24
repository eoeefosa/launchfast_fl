import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/order.dart';
import '../../constants/static_data.dart';
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

    final rider = order.riderId != null
        ? StaticData.riders.cast<dynamic>().firstWhere(
            (r) => r.id == order.riderId,
            orElse: () => null,
          )
        : null;

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
                      _StatusIcon(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 40),
                  OrderTimeline(status: order.status),
                ],
              ),
            ),
            if (rider != null) _RiderCard(rider: rider, isIOS: isIOS),
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

class _StatusIcon extends StatelessWidget {
  final OrderStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.timer_rounded;
    if (status == OrderStatus.preparing) icon = Icons.restaurant_rounded;
    if (status == OrderStatus.outForDelivery)
      icon = Icons.delivery_dining_rounded;
    if (status == OrderStatus.delivered) icon = Icons.check_circle_rounded;

    return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.surface, size: 40),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
          curve: Curves.easeInOut,
        );
  }
}

class _RiderCard extends StatelessWidget {
  final dynamic rider;
  final bool isIOS;

  const _RiderCard({required this.rider, required this.isIOS});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: AppColors.lightBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: AppColors.primary, width: 2),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=100&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Partner',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rider.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _CallButton(phoneNumber: rider.phoneNumber, isIOS: isIOS),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final String phoneNumber;
  final bool isIOS;

  const _CallButton({required this.phoneNumber, required this.isIOS});

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => launchUrl(Uri.parse('tel:$phoneNumber')),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            CupertinoIcons.phone_fill,
            color: Theme.of(context).colorScheme.surface,
            size: 20,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => launchUrl(Uri.parse('tel:$phoneNumber')),
      icon: Icon(Icons.phone_in_talk_rounded, color: Theme.of(context).colorScheme.surface),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
