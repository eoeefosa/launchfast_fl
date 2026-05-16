import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/auth/data/user_profile.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';

@immutable
class ActionConfig {
  const ActionConfig(this.label, this.status, this.color, this.icon);

  final String label;
  final OrderStatus status;
  final Color color;
  final IconData icon;
}

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.textColor,
    required this.muted,
    required this.surface,
    required this.border,
    required this.onUpdateStatus,
  });

  final Order order;
  final Color textColor;
  final Color muted;
  final Color surface;
  final Color border;
  final Future<void> Function(String orderId, OrderStatus status) onUpdateStatus;

  Color get _statusColor => switch (order.status) {
        OrderStatus.pending => const Color(0xFFF59E0B),
        OrderStatus.accepted => const Color(0xFF6366F1),
        OrderStatus.preparing => const Color(0xFF06B6D4),
        OrderStatus.readyForPickup || OrderStatus.pickingUp => const Color(0xFF8B5CF6),
        OrderStatus.onTheWay || OrderStatus.outForDelivery => AppColors.primary,
        OrderStatus.delivered => Colors.green,
        OrderStatus.cancelled => Colors.red,
        _ => AppColors.lightMuted,
      };

  List<ActionConfig> get _actions {
    final isPickup = order.deliveryType.toLowerCase() == 'pickup' || 
                    order.deliveryType.toLowerCase() == 'store_pickup';
                    
    return switch (order.status) {
        OrderStatus.pending => [
            const ActionConfig(
              'Accept',
              OrderStatus.accepted,
              Colors.green,
              Icons.check_circle_outline,
            ),
            const ActionConfig(
              'Reject',
              OrderStatus.cancelled,
              Colors.red,
              Icons.cancel_outlined,
            ),
          ],
        OrderStatus.accepted => [
            const ActionConfig(
              'Start Preparing',
              OrderStatus.preparing,
              Color(0xFF06B6D4),
              Icons.soup_kitchen_outlined,
            ),
          ],
        OrderStatus.preparing => [
            ActionConfig(
              isPickup ? 'Ready for Pickup' : 'Ready for Delivery',
              OrderStatus.readyForPickup,
              const Color(0xFF8B5CF6),
              Icons.done_all,
            ),
          ],
        OrderStatus.readyForPickup => [
            const ActionConfig(
              'On the Way',
              OrderStatus.onTheWay,
              AppColors.primary,
              Icons.directions_bike_rounded,
            ),
            if (isPickup)
              const ActionConfig(
                'Mark Picked Up',
                OrderStatus.delivered,
                Colors.green,
                Icons.check_circle_rounded,
              ),
          ],
        OrderStatus.onTheWay || OrderStatus.outForDelivery => [
            ActionConfig(
              isPickup ? 'Mark Picked Up' : 'Mark Arrived',
              OrderStatus.delivered,
              Colors.green,
              isPickup ? Icons.check_circle_rounded : Icons.home_work_rounded,
            ),
          ],
        _ => const [],
      };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final shortId = _shortId(order.id).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              shortId: shortId,
              date: order.date,
              statusColor: _statusColor,
              statusLabel: order.status.displayLabel,
              textColor: textColor,
              muted: muted,
            ),
            const SizedBox(height: 12),
            Divider(color: border, height: 1),
            const SizedBox(height: 12),
            if (order.user != null) ...[
              _CustomerRow(user: order.user!, textColor: textColor, muted: muted),
              const SizedBox(height: 8),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),
            ],
            _ItemsSection(
              items: order.items,
              bg: bg,
              textColor: textColor,
              muted: muted,
            ),
            const SizedBox(height: 16),
            _FinancialSummary(
              order: order,
              border: border,
              textColor: textColor,
              muted: muted,
            ),
            if (_actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _actions
                    .map((a) => _ActionButton(config: a, order: order, onTap: onUpdateStatus))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _shortId(String id) =>
      id.length >= 8 ? id.substring(id.length - 8) : id;
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.shortId,
    required this.date,
    required this.statusColor,
    required this.statusLabel,
    required this.textColor,
    required this.muted,
  });

  final String shortId;
  final String date;
  final Color statusColor;
  final String statusLabel;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.receipt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$shortId',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day}/${dt.month}/${dt.year} • $h:$m $ampm';
    } catch (_) {
      return iso;
    }
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.user,
    required this.textColor,
    required this.muted,
  });

  final UserProfile user;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final hasPhone = user.phone != null && user.phone!.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (hasPhone)
                Text(
                  user.phone!,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
            ],
          ),
        ),
        if (hasPhone)
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.primary),
            onPressed: () => _call(user.phone!),
          ),
      ],
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({
    required this.items,
    required this.bg,
    required this.textColor,
    required this.muted,
  });

  final List<CartItem> items;
  final Color bg;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ItemRow(item: item, textColor: textColor, muted: muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.textColor,
    required this.muted,
  });

  final CartItem item;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.menuItem.name,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (item.selectedSides?.isNotEmpty ?? false)
                for (final e in item.selectedSides!.entries)
                  if (e.value > 0) _Modifier('Side: ${e.key} (x${e.value})', muted),
              if (item.selectedDrinks?.isNotEmpty ?? false)
                for (final e in item.selectedDrinks!.entries)
                  if (e.value > 0) _Modifier('Drink: ${e.key} (x${e.value})', muted),
              if (item.extras?.isNotEmpty ?? false)
                _Modifier('Extras: ${item.extras!.join(", ")}', muted),
              if (item.selectedMeats?.isNotEmpty ?? false)
                for (final e in item.selectedMeats!.entries)
                  if (e.value > 0) _Modifier('Meat: ${e.key} (x${e.value})', muted),
              if (item.selectedAddons?.isNotEmpty ?? false)
                for (final e in item.selectedAddons!.entries)
                  if (e.value > 0) _Modifier('Addon: ${e.key} (x${e.value})', muted),
            ],
          ),
        ),
        Text(
          '₦${(item.menuItem.price * item.quantity).toStringAsFixed(0)}',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _Modifier extends StatelessWidget {
  const _Modifier(this.text, this.muted);

  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('↳ ', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(
            child: Text(text, style: TextStyle(color: muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({
    required this.order,
    required this.border,
    required this.textColor,
    required this.muted,
  });

  final Order order;
  final Color border;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Subtotal',
              value: '₦${order.subtotal.toStringAsFixed(0)}',
              muted: muted,
              textColor: textColor,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Transportation (${order.deliveryType})',
              value: '₦${order.deliveryFee.toStringAsFixed(0)}',
              muted: muted,
              textColor: textColor,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (order.isPriority)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            '⚡ Priority',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (order.isPriority) const SizedBox(width: 8),
                    Text(
                      '₦${(order.subtotal + order.deliveryFee).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.muted,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color muted;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: muted, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.config,
    required this.order,
    required this.onTap,
  });

  final ActionConfig config;
  final Order order;
  final Future<void> Function(String, OrderStatus) onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => onTap(order.id, config.status),
      icon: Icon(config.icon, size: 16),
      label: Text(config.label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: config.color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
