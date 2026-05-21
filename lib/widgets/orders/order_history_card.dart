import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/order.dart';
import '../../constants/app_colors.dart';

class OrderHistoryCard extends StatelessWidget {
  final Order order;

  const OrderHistoryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isPendingPayment = order.status == OrderStatus.pendingPayment;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isPendingPayment
            ? Colors.orange.withValues(alpha: 0.06)
            : scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPendingPayment
              ? Colors.orange.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: isPendingPayment ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/orders/${order.id}', extra: order);
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isPendingPayment
                          ? Colors.orange.withValues(alpha: 0.12)
                          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isPendingPayment
                          ? Icons.payment_rounded
                          : Icons.restaurant_rounded,
                      color: isPendingPayment
                          ? Colors.orange.shade700
                          : scheme.onSurface.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.length > 4 ? order.id.substring(order.id.length - 4).toUpperCase() : order.id.toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (order.date.isNotEmpty)
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • hh:mm a',
                            ).format(DateTime.parse(order.date)),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.lightMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₦${order.total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: isPendingPayment ? Colors.orange.shade700 : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _StatusBadge(status: order.status),
                    ],
                  ),
                ],
              ),
              if (isPendingPayment) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Payment required — tap to pay or cancel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == OrderStatus.delivered;
    final isCancelled = status == OrderStatus.cancelled;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50;
    Color textColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;

    if (isDelivered) {
      bgColor = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
      textColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (isCancelled) {
      bgColor = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
      textColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayLabel.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}


