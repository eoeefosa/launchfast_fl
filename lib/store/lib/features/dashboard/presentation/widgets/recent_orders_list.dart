import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';

class DashboardRecentOrdersList extends StatelessWidget {
  final bool isLoading;
  final List<Order> orders;
  final VoidCallback onRefresh;

  const DashboardRecentOrdersList({
    super.key,
    required this.isLoading,
    required this.orders,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onRefresh,
              child: const Text(
                'Refresh',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildList(surface, border, muted, textColor),
      ],
    );
  }

  Widget _buildList(Color surface, Color border, Color muted, Color textColor) {
    if (isLoading) {
      return Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 72,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, color: muted, size: 40),
              const SizedBox(height: 8),
              Text('No orders yet', style: TextStyle(color: muted)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        final statusColor = _statusColor(order.status);
        final statusLabel = order.status.name;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              '#${order.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              '₦${order.total.toStringAsFixed(0)} • ${order.items.length} item(s)',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.accepted:
        return const Color(0xFF6366F1);
      case OrderStatus.preparing:
        return const Color(0xFF06B6D4);
      case OrderStatus.readyForPickup:
      case OrderStatus.pickingUp:
        return const Color(0xFF8B5CF6);
      case OrderStatus.onTheWay:
      case OrderStatus.outForDelivery:
        return AppColors.primary;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return AppColors.lightMuted;
    }
  }
}
