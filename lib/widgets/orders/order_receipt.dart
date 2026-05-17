import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:campuschow/constants/app_colors.dart';
import 'package:campuschow/models/order.dart';
import 'package:campuschow/providers/cart_provider.dart';

/// The full order receipt: line items, fee breakdown, total, and optional
/// "Edit Selections" button for queued orders.
class OrderReceipt extends StatelessWidget {
  const OrderReceipt({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipt',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Line items
                ...order.items.map((item) => OrderDetailItem(item: item)),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Fee rows
                OrderSummaryRow(label: 'Subtotal', value: order.subtotal),
                if (order.serviceFee > 0)
                  OrderSummaryRow(label: 'Service Fee', value: order.serviceFee),
                if (order.deliveryFee > 0)
                  OrderSummaryRow(label: 'Delivery Fee', value: order.deliveryFee),
                if (order.walletDeduction > 0)
                  OrderSummaryRow(
                    label: 'Wallet Applied',
                    value: -order.walletDeduction,
                    isHighlight: true,
                  ),

                const SizedBox(height: 16),
                OrderTotalRow(total: order.total),

                if (order.status == OrderStatus.queued) ...[
                  const SizedBox(height: 24),
                  OrderEditButton(order: order),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A labelled price row in the receipt fee breakdown.
class OrderSummaryRow extends StatelessWidget {
  const OrderSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final String label;
  final double value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: muted),
          ),
          Text(
            value < 0
                ? '-₦${value.abs().toStringAsFixed(0)}'
                : '₦${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isHighlight ? Colors.green : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// The bold grand-total line at the bottom of the receipt.
class OrderTotalRow extends StatelessWidget {
  const OrderTotalRow({super.key, required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 18, fontWeight: FontWeight.w900);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Total', style: style),
        Text(
          '₦${total.toStringAsFixed(0)}',
          style: style.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

/// One cart-item row in the receipt: quantity badge, name, and selected addons.
class OrderDetailItem extends StatelessWidget {
  const OrderDetailItem({super.key, required this.item});

  final CartItem item;

  /// Builds a flat list of human-readable addon strings from the item's
  /// selection maps (meats, sides, drinks, generic addons).
  List<String> _buildAddonLabels() {
    final labels = <String>[];

    void addFromMap(Map<String, int>? map, String suffix) {
      map?.forEach((name, count) {
        if (count > 0) labels.add('${count}x $name$suffix');
      });
    }

    addFromMap(item.selectedMeats, ' Meat');
    addFromMap(item.selectedSides, ' Side');
    addFromMap(item.selectedDrinks, ' Drink');
    // Generic addons have no suffix.
    item.selectedAddons?.forEach((name, count) {
      if (count > 0) labels.add('${count}x $name');
    });

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final addons = _buildAddonLabels();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity badge
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '${item.quantity}x',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + addons
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
                        color: colorScheme.onSurfaceVariant,
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

/// Shown only for queued orders; loads the order into the cart for editing.
class OrderEditButton extends StatelessWidget {
  const OrderEditButton({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          backgroundColor: colorScheme.onSurface,
          foregroundColor: colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
