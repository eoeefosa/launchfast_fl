import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';

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
    required this.isUpdating,
    required this.textColor,
    required this.muted,
    required this.surface,
    required this.border,
    required this.onUpdateStatus,
  });

  final Order order;
  final bool isUpdating;
  final Color textColor;
  final Color muted;
  final Color surface;
  final Color border;
  final Future<void> Function(String orderId, OrderStatus status)
  onUpdateStatus;

  Color get _statusColor => switch (order.status) {
    OrderStatus.pending => const Color(0xFFF59E0B),
    OrderStatus.accepted => const Color(0xFF6366F1),
    OrderStatus.preparing => const Color(0xFF06B6D4),
    OrderStatus.readyForPickup ||
    OrderStatus.pickingUp => const Color(0xFF8B5CF6),
    OrderStatus.onTheWay || OrderStatus.outForDelivery => AppColors.primary,
    OrderStatus.delivered => Colors.green,
    OrderStatus.cancelled => Colors.red,
    OrderStatus.priceAdjusted => const Color(0xFFF59E0B),
    _ => AppColors.lightMuted,
  };

  List<ActionConfig> get _actions {
    final isPickup =
        order.deliveryType.toLowerCase() == 'pickup' ||
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
          'Adjust Price',
          OrderStatus.priceAdjusted,
          Colors.orange,
          Icons.price_change_outlined,
        ),
        const ActionConfig(
          'Reject',
          OrderStatus.cancelled,
          Colors.red,
          Icons.cancel_outlined,
        ),
      ],
      OrderStatus.priceAdjusted => [
        if (order.originalTotal != null && order.originalTotal! >= order.total)
          const ActionConfig(
            'Accept',
            OrderStatus.accepted,
            Colors.green,
            Icons.check_circle_outline,
          ),
        const ActionConfig(
          'Adjust Price Again',
          OrderStatus.priceAdjusted,
          Colors.orange,
          Icons.price_change_outlined,
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
        if (!isPickup)
          const ActionConfig(
            'On the Way',
            OrderStatus.onTheWay,
            AppColors.primary,
            Icons.directions_bike_rounded,
          ),
      ],
      OrderStatus.readyForPickup => [
        if (!isPickup)
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

  Widget _buildElapsedBadge(String isoDate) {
    if (isoDate.isEmpty) return const SizedBox.shrink();
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final elapsed = DateTime.now().difference(dt).inMinutes;

      final Color bgColor;
      final Color textColor;
      final String label;
      final IconData icon;

      if (elapsed < 3) {
        bgColor = Colors.green.withValues(alpha: 0.12);
        textColor = Colors.green.shade700;
        label = 'Just now (${elapsed}m ago)';
        icon = Icons.timer_outlined;
      } else if (elapsed < 5) {
        bgColor = Colors.orange.withValues(alpha: 0.12);
        textColor = Colors.orange.shade700;
        label = '${elapsed}m elapsed';
        icon = Icons.hourglass_empty_rounded;
      } else {
        bgColor = Colors.red.withValues(alpha: 0.12);
        textColor = Colors.red.shade700;
        label = '${elapsed}m - UNATTENDED!';
        icon = Icons.warning_amber_rounded;
      }

      return DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final shortId = _shortId(order.id).toUpperCase();
    final isPickup =
        order.deliveryType.toLowerCase() == 'pickup' ||
        order.deliveryType.toLowerCase() == 'store_pickup';

    return Opacity(
      opacity: isUpdating ? 0.72 : 1,
      child: Stack(
        children: [
          DecoratedBox(
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: isPickup
                              ? Colors.teal.withValues(alpha: 0.12)
                              : Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPickup
                                ? Colors.teal.withValues(alpha: 0.3)
                                : Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPickup
                                    ? Icons.shopping_bag_outlined
                                    : Icons.delivery_dining_rounded,
                                size: 14,
                                color: isPickup ? Colors.teal : Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPickup ? 'Pickup' : 'Delivery',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPickup ? Colors.teal : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isPickup &&
                          (order.status == OrderStatus.pending ||
                              order.status == OrderStatus.accepted ||
                              order.status == OrderStatus.preparing)) ...[
                        const SizedBox(width: 8),
                        _buildElapsedBadge(order.date),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 12),
                  _CustomerRow(
                    name: order.resolvedCustomerName,
                    phone: order.resolvedCustomerPhone,
                    address: order.customerDetails?.address,
                    textColor: textColor,
                    muted: muted,
                  ),
                  const SizedBox(height: 8),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 12),

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
                          .map(
                            (a) => _ActionButton(
                              config: a,
                              order: order,
                              onTap: onUpdateStatus,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUpdating)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
    required this.name,
    this.phone,
    this.address,
    required this.textColor,
    required this.muted,
  });

  final String name;
  final String? phone;
  final String? address;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (hasPhone)
                Text(phone!, style: TextStyle(color: muted, fontSize: 13)),
              if (address != null && address!.trim().isNotEmpty)
                Text(
                  address!,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (hasPhone)
          IconButton(
            tooltip: 'Call customer',
            icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
            onPressed: () => _call(phone!),
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.textColor,
    required this.muted,
  });

  final CartItem item;
  final Color textColor;
  final Color muted;

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

    return Column(
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
                          color: muted.withValues(alpha: 0.5),
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
                          color: row.isModifier ? muted : textColor,
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
                  color: row.isModifier ? muted : textColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
              label: 'Food Sales',
              value: '₦${order.subtotal.toStringAsFixed(0)}',
              muted: muted,
              textColor: textColor,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Delivery Revenue (${order.deliveryType})',
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

  Future<String?> _selectRejectionReason(BuildContext context) async {
    final controller = TextEditingController();
    const customReason = 'Custom';

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogCtx) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          var selectedReason = 'Out of stock';
          String? customError;

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              backgroundColor: isDark ? null : Colors.white,
              title: const Text('Reject Order'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a reason so the customer is notified clearly.',
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selectedReason == 'Out of stock'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Out of stock'),
                    onTap: () {
                      setDialogState(() {
                        selectedReason = 'Out of stock';
                        customError = null;
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selectedReason == 'Not taking orders'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Not taking orders'),
                    onTap: () {
                      setDialogState(() {
                        selectedReason = 'Not taking orders';
                        customError = null;
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selectedReason == customReason
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Custom'),
                    onTap: () {
                      setDialogState(() {
                        selectedReason = customReason;
                      });
                    },
                  ),
                  if (selectedReason == customReason) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Enter rejection reason',
                        border: const OutlineInputBorder(),
                        errorText: customError,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    final reason = selectedReason == customReason
                        ? controller.text.trim()
                        : selectedReason;
                    if (reason.isEmpty) {
                      setDialogState(() {
                        customError = 'Enter a rejection reason';
                      });
                      return;
                    }
                    Navigator.pop(dialogCtx, reason);
                  },
                  child: const Text(
                    'Reject Order',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showRejectionDialog(BuildContext context) async {
    final reason = await _selectRejectionReason(context);

    if (reason != null && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final storeProvider = context.read<StoreProvider>();
        await storeProvider.updateOrderStatus(
          order.id,
          OrderStatus.cancelled.backendName,
          rejectionReason: reason,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Order rejected successfully.')),
        );
        onTap(order.id, OrderStatus.cancelled);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error rejecting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPriceAdjustmentDialog(BuildContext context) async {
    final provider = context.read<StoreProvider>();
    final controllers = <String, TextEditingController>{};
    for (final item in order.items) {
      controllers[item.id] = TextEditingController(
        text: item.menuItem.price.toStringAsFixed(0),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Adjust Order Prices'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Update the base price of any food item below. The customer will be notified to pay the balance or cancel.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.menuItem.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Current: ₦${item.menuItem.price.toStringAsFixed(0)} per portion',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: controllers[item.id],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: '₦',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Submit Adjustment',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final updatedItems = <Map<String, dynamic>>[];
      final messenger = ScaffoldMessenger.of(context);
      for (final item in order.items) {
        final newPrice = double.tryParse(controllers[item.id]?.text ?? '');
        if (newPrice == null || newPrice <= 0) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Please enter valid positive numbers for all prices.',
              ),
            ),
          );
          return;
        }
        updatedItems.add({'itemId': item.id, 'newPrice': newPrice});
      }

      try {
        await provider.adjustOrderPrice(order.id, updatedItems);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Prices adjusted successfully. Customer notified.'),
          ),
        );
        onTap(order.id, OrderStatus.priceAdjusted);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error adjusting prices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        if (config.status == OrderStatus.cancelled) {
          await _showRejectionDialog(context);
        } else if (config.status == OrderStatus.priceAdjusted) {
          await _showPriceAdjustmentDialog(context);
        } else {
          await onTap(order.id, config.status);
        }
      },
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
