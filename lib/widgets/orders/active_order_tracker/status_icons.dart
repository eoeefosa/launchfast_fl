import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:launchfast/models/order.dart';

class StatusIcon extends StatelessWidget {
  final OrderStatus status;

  const StatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.timer_rounded;
    if (status == OrderStatus.preparing) icon = Icons.restaurant_rounded;
    if (status == OrderStatus.outForDelivery) {
      icon = Icons.delivery_dining_rounded;
    }
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
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.surface,
            size: 40,
          ),
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
