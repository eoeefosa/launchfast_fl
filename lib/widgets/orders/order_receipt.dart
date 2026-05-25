import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:campuschow/providers/store_provider.dart';
import 'package:campuschow/models/menu_item.dart';
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
                  OrderSummaryRow(
                    label: 'Service Fee',
                    value: order.serviceFee,
                  ),
                if (order.deliveryFee > 0)
                  OrderSummaryRow(
                    label: 'Delivery Fee',
                    value: order.deliveryFee,
                  ),
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
          Text(label, style: TextStyle(fontSize: 14, color: muted)),
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
class OrderDetailRow {
  final String leftText;
  final String rightText;
  final bool isModifier;

  OrderDetailRow({
    required this.leftText,
    required this.rightText,
    this.isModifier = false,
  });
}

class OrderDetailItem extends StatelessWidget {
  const OrderDetailItem({super.key, required this.item});

  final CartItem item;

  double _getModifierUnitPrice({
    required String type,
    required String key,
    required Map<String, double> meatPrices,
    required double saladPrice,
    required List<MenuItem> allMenuItems,
  }) {
    final item = allMenuItems.firstWhereOrNull(
      (m) => m.id == key || m.name == key,
    );
    if (item != null) return item.price;
    switch (type) {
      case 'meat':
        return meatPrices[key] ?? 0.0;
      case 'side':
        return saladPrice;
      default:
        return 0.0;
    }
  }

  List<OrderDetailRow> _buildRows(BuildContext context) {
    final rows = <OrderDetailRow>[];

    final storeProvider = context.read<StoreProvider>();
    final allMenuItems = storeProvider.menuItems;
    final meatPrices = storeProvider.meatPrices;
    final saladPrice = storeProvider.saladPrice;

    // Resolve name
    String displayName = item.menuItem.name;
    if (displayName.toUpperCase() == 'CHICKEN & TURKEY' ||
        (displayName.toLowerCase().contains('chicken') &&
            displayName.toLowerCase().contains('turkey'))) {
      final hasTurkey =
          item.selectedMeats?.keys.any(
            (k) => k.toLowerCase().contains('turkey'),
          ) ??
          false;
      displayName = hasTurkey ? 'TURKEY' : 'CHICKEN';
    }

    // Is it a main item (Rice & Pasta, Swallow & Soup, Swallow, etc.)?
    final cat = item.menuItem.category.toLowerCase();
    final type = item.menuItem.type?.toLowerCase() ?? '';
    final isMain =
        type == 'main' ||
        type == 'swallow' ||
        cat.contains('rice') ||
        cat.contains('pasta') ||
        cat.contains('spaghetti') ||
        cat.contains('swallow');

    double basePrice = item.menuItem.price;
    if (item.selectedSizeId != null) {
      final size = item.menuItem.sizes.firstWhereOrNull(
        (s) => s.id == item.selectedSizeId,
      );
      if (size != null) {
        basePrice = size.price;
      }
    }

    if (isMain) {
      rows.add(
        OrderDetailRow(
          leftText:
              '$displayName  ${item.quantity} ${item.quantity == 1 ? 'portion' : 'portions'} × ₦${basePrice.toStringAsFixed(0)}',
          rightText: '₦${(basePrice * item.quantity).toStringAsFixed(0)}',
        ),
      );
    } else {
      rows.add(
        OrderDetailRow(
          leftText: '$displayName ×${item.quantity}',
          rightText: '₦${(basePrice * item.quantity).toStringAsFixed(0)}',
        ),
      );
    }

    // Now, build modifiers.
    final hasMeatsDetails =
        item.selectedMeatsDetails != null &&
        item.selectedMeatsDetails!.isNotEmpty;
    final hasMeatsMap =
        item.selectedMeats?.entries.any((e) => e.value > 0) ?? false;

    void addMeat(String name, double price, int qty) {
      final unitPrice = price > 0
          ? price
          : _getModifierUnitPrice(
              type: 'meat',
              key: name,
              meatPrices: meatPrices,
              saladPrice: saladPrice,
              allMenuItems: allMenuItems,
            );
      rows.add(
        OrderDetailRow(
          leftText: '$name ×$qty',
          rightText: '₦${(unitPrice * qty).toStringAsFixed(0)}',
          isModifier: true,
        ),
      );
    }

    if (hasMeatsDetails) {
      for (final dynamic element in item.selectedMeatsDetails!) {
        if (element is Map) {
          final name = element['name']?.toString() ?? 'Option';
          final price = (element['price'] as num?)?.toDouble() ?? 0.0;
          final qty = (element['quantity'] as num?)?.toInt() ?? 1;
          addMeat(name, price, qty);
        }
      }
    } else if (hasMeatsMap) {
      item.selectedMeats?.forEach((name, count) {
        if (count > 0) {
          addMeat(name, 0.0, count);
        }
      });
    } else if (isMain) {}

    // Add other modifiers (Sides, Drinks, Addons, Soups)
    void addModifier(String type, String name, double price, int qty) {
      final unitPrice = price > 0
          ? price
          : _getModifierUnitPrice(
              type: type,
              key: name,
              meatPrices: meatPrices,
              saladPrice: saladPrice,
              allMenuItems: allMenuItems,
            );
      rows.add(
        OrderDetailRow(
          leftText: '$name ×$qty',
          rightText: '₦${(unitPrice * qty).toStringAsFixed(0)}',
          isModifier: true,
        ),
      );
    }

    if (item.selectedSidesDetails != null &&
        item.selectedSidesDetails!.isNotEmpty) {
      for (final dynamic element in item.selectedSidesDetails!) {
        if (element is Map) {
          final name = element['name']?.toString() ?? 'Option';
          final price = (element['price'] as num?)?.toDouble() ?? 0.0;
          final qty = (element['quantity'] as num?)?.toInt() ?? 1;
          addModifier('side', name, price, qty);
        }
      }
    } else {
      item.selectedSides?.forEach((name, count) {
        if (count > 0) addModifier('side', '$name Side', 0.0, count);
      });
    }

    if (item.selectedDrinksDetails != null &&
        item.selectedDrinksDetails!.isNotEmpty) {
      for (final dynamic element in item.selectedDrinksDetails!) {
        if (element is Map) {
          final name = element['name']?.toString() ?? 'Option';
          final price = (element['price'] as num?)?.toDouble() ?? 0.0;
          final qty = (element['quantity'] as num?)?.toInt() ?? 1;
          addModifier('drink', name, price, qty);
        }
      }
    } else {
      item.selectedDrinks?.forEach((name, count) {
        if (count > 0) addModifier('drink', '$name Drink', 0.0, count);
      });
    }

    if (item.selectedAddonsDetails != null &&
        item.selectedAddonsDetails!.isNotEmpty) {
      for (final dynamic element in item.selectedAddonsDetails!) {
        if (element is Map) {
          final name = element['name']?.toString() ?? 'Option';
          final price = (element['price'] as num?)?.toDouble() ?? 0.0;
          final qty = (element['quantity'] as num?)?.toInt() ?? 1;
          addModifier('addon', name, price, qty);
        }
      }
    } else {
      item.selectedAddons?.forEach((name, count) {
        if (count > 0) addModifier('addon', name, 0.0, count);
      });
    }

    if (item.selectedSoup != null) {
      final name = item.selectedSoup!['name']?.toString() ?? 'Soup';
      final price = (item.selectedSoup!['price'] as num?)?.toDouble() ?? 0.0;
      rows.add(
        OrderDetailRow(
          leftText: '$name ×${item.quantity}',
          rightText: '₦${(price * item.quantity).toStringAsFixed(0)}',
          isModifier: true,
        ),
      );
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = _buildRows(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (row.isModifier) ...[
                        Text(
                          '↳ ',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          row.leftText,
                          style: TextStyle(
                            fontWeight: row.isModifier
                                ? FontWeight.w500
                                : FontWeight.w800,
                            fontSize: row.isModifier ? 13 : 15,
                            color: row.isModifier
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  row.rightText,
                  style: TextStyle(
                    fontWeight: row.isModifier
                        ? FontWeight.w500
                        : FontWeight.w800,
                    fontSize: row.isModifier ? 13 : 15,
                    color: row.isModifier
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
