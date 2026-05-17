import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';

import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'widgets/order_card.dart';

class StoreTopSellingScreen extends StatefulWidget {
  final List<MapEntry<String, int>> items;
  final List<Order> orders;

  const StoreTopSellingScreen({
    super.key,
    required this.items,
    required this.orders,
  });

  @override
  State<StoreTopSellingScreen> createState() => _StoreTopSellingScreenState();
}

class _StoreTopSellingScreenState extends State<StoreTopSellingScreen> {
  late List<Order> _localOrders;

  @override
  void initState() {
    super.initState();
    _localOrders = List.of(widget.orders);
  }

  // Helper to find all orders containing a specific item name
  List<Order> _getOrdersForItem(String itemName) {
    return _localOrders.where((order) {
      return order.items.any((cartItem) => cartItem.menuItem.name == itemName);
    }).toList();
  }

  Future<void> _updateStatus(String orderId, OrderStatus newStatus) async {
    try {
      final storeProvider = context.read<StoreProvider>();
      await storeProvider.updateOrderStatus(orderId, newStatus.backendName);
      
      if (!mounted) return;
      
      // Fetch fresh orders
      final newOrders = await storeProvider.fetchStoreOrders();
      if (mounted) {
        setState(() {
          _localOrders = newOrders;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated to ${newStatus.displayLabel}')),
        );
      }
    } catch (e, stack) {
      debugPrint('[StoreTopSellingScreen] _updateStatus error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Top Selling Items',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final entry = widget.items[index];
          final itemName = entry.key;
          final soldCount = entry.value;
          final itemOrders = _getOrdersForItem(itemName);

          return Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  itemName,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '$soldCount sold total',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Recent Buyers',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (itemOrders.isEmpty)
                          Text('No recent buyers found.', style: TextStyle(color: muted, fontSize: 13))
                        else
                          ...itemOrders.map((order) {
                            final customerName = order.user?.name ?? 'Guest User';
                            
                            // Calculate how many of THIS item the customer bought in this order
                            int quantityInOrder = 0;
                            for (var cartItem in order.items) {
                              if (cartItem.menuItem.name == itemName) {
                                quantityInOrder += cartItem.quantity;
                              }
                            }

                            return InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) {
                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    final modalBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(top: 60),
                                      decoration: BoxDecoration(
                                        color: modalBg,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      child: SafeArea(
                                        child: Column(
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.symmetric(vertical: 12),
                                              height: 4,
                                              width: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(alpha: 0.3),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            Expanded(
                                              child: ListView(
                                                padding: const EdgeInsets.all(16),
                                                children: [
                                                  OrderCard(
                                                    order: order,
                                                    textColor: textColor,
                                                    muted: muted,
                                                    surface: surface,
                                                    border: border,
                                                    onUpdateStatus: (id, status) async {
                                                      Navigator.pop(ctx);
                                                      await _updateStatus(id, status);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.lightBorder,
                                      child: Text(
                                        customerName[0].toUpperCase(),
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customerName,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Ordered $quantityInOrder',
                                            style: TextStyle(color: muted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(order.status).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        order.status.displayLabel,
                                        style: TextStyle(
                                          color: _getStatusColor(order.status),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.preparing:
        return const Color(0xFF06B6D4);
      case OrderStatus.readyForPickup:
        return const Color(0xFF10B981);
      case OrderStatus.outForDelivery:
        return const Color(0xFF8B5CF6);
      case OrderStatus.delivered:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
