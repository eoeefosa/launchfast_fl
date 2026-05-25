import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/orders/presentation/cart_provider.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';

class OrderHistoryCard extends StatelessWidget {
  final Order order;

  const OrderHistoryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // final isDelivered = order.status == OrderStatus.delivered;
    // final isCancelled = order.status == OrderStatus.cancelled;

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

    Color bgColor = Colors.orange.shade50;
    Color textColor = Colors.orange.shade700;

    if (isDelivered) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (isCancelled) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
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

class _OrderDetailRow {
  final String leftText;
  final String rightText;
  final bool isModifier;

  _OrderDetailRow({
    required this.leftText,
    required this.rightText,
    this.isModifier = false,
  });
}

class _DetailItem extends StatelessWidget {
  final CartItem item;

  const _DetailItem({required this.item});

  double _getModifierUnitPrice({
    required String type,
    required String key,
    required Map<String, double> meatPrices,
    required double saladPrice,
    required List<dynamic> allMenuItems,
  }) {
    final item = allMenuItems.firstWhereOrNull(
      (dynamic m) => m.id == key || m.name == key,
    );
    if (item != null) return (item.price as num).toDouble();
    switch (type) {
      case 'meat':
        return meatPrices[key] ?? 0.0;
      case 'side':
        return saladPrice;
      default:
        return 0.0;
    }
  }

  List<_OrderDetailRow> _buildRows(BuildContext context) {
    final rows = <_OrderDetailRow>[];

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
      final size = item.menuItem.sizes?.firstWhereOrNull(
        (s) => s.id == item.selectedSizeId,
      );
      if (size != null) {
        basePrice = size.price;
      }
    }

    if (isMain) {
      rows.add(
        _OrderDetailRow(
          leftText:
              '$displayName  ${item.quantity} ${item.quantity == 1 ? 'portion' : 'portions'} × ₦${basePrice.toStringAsFixed(0)}',
          rightText: '₦${(basePrice * item.quantity).toStringAsFixed(0)}',
        ),
      );
    } else {
      rows.add(
        _OrderDetailRow(
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
        _OrderDetailRow(
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
        _OrderDetailRow(
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
        _OrderDetailRow(
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
                            color: AppColors.lightMuted.withValues(alpha: 0.5),
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
                                ? AppColors.lightMuted
                                : Colors.black,
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
                    color: row.isModifier ? AppColors.lightMuted : Colors.black,
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
