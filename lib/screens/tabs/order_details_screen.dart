import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/models/order.dart';
import 'package:campuschow/providers/cart_provider.dart';
import 'package:campuschow/constants/app_colors.dart';
import 'package:campuschow/widgets/orders/active_order_tracker.dart';

import 'package:campuschow/repositories/order_repository.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order? order;
  final String? orderId;

  const OrderDetailsScreen({super.key, this.order, this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _order;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _order = widget.order;
    } else if (widget.orderId != null) {
      _fetchOrder();
    }
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await OrderRepository().getOrderById(widget.orderId!);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load order details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Order not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOrder,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final isActive = order.status != OrderStatus.delivered && 
                     order.status != OrderStatus.cancelled;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isActive) ...[
              ActiveOrderTracker(order: order),
              const SizedBox(height: 32),
            ],
            
            // Receipt Section
            Text(
              'Receipt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  ...order.items.map((i) => _DetailItem(item: i)),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.lightBorder.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  
                  // Totals
                  _SummaryRow(label: 'Subtotal', value: order.subtotal),
                  if (order.serviceFee > 0)
                    _SummaryRow(label: 'Service Fee', value: order.serviceFee),
                  if (order.deliveryFee > 0)
                    _SummaryRow(label: 'Delivery Fee', value: order.deliveryFee),
                  if (order.walletDeduction > 0)
                    _SummaryRow(
                      label: 'Wallet Applied', 
                      value: -order.walletDeduction, 
                      isHighlight: true
                    ),
                  
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '₦${order.total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  if (order.status == OrderStatus.queued)
                    _EditOrderButton(order: order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isHighlight;

  const _SummaryRow({
    required this.label, 
    required this.value, 
    this.isHighlight = false
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value < 0 ? '-₦${value.abs().toStringAsFixed(0)}' : '₦${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isHighlight ? Colors.green : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          foregroundColor: Theme.of(context).colorScheme.surface,
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
