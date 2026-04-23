import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../constants/app_colors.dart';

class OrderHistoryCard extends StatelessWidget {
  final Order order;

  const OrderHistoryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          title: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.lightMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(order.id.length - 4).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(order.date)),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.lightMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${order.total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              _StatusBadge(status: order.status),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Divider(color: AppColors.lightBorder.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  ...order.items.map((i) => _DetailItem(item: i)),
                  const SizedBox(height: 24),
                  if (order.status == OrderStatus.queued)
                    _EditOrderButton(order: order),
                ],
              ),
            ),
          ],
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
    
    Color bgColor = Colors.orange[50]!;
    Color textColor = Colors.orange[700]!;

    if (isDelivered) {
      bgColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
    } else if (isCancelled) {
      bgColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
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

class _DetailItem extends StatelessWidget {
  final CartItem item;

  const _DetailItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final addons = <String>[];
    if (item.selectedMeats != null) {
      item.selectedMeats!.forEach((k, v) {
        if (v > 0) addons.add('${v}x $k Meat');
      });
    }
    if (item.hasSalad) addons.add('Salad');
    if (item.selectedAddons != null) {
      item.selectedAddons!.forEach((k, v) {
        if (v > 0) addons.add('${v}x $k');
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}x',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (addons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      addons.join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.lightMuted,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditOrderButton extends StatelessWidget {
  final Order order;

  const _EditOrderButton({required this.order});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<CartProvider>().loadOrder(order, isEditing: true);
          context.push('/cart');
        },
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit Selections'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
