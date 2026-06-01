import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'widgets/order_card.dart';
import 'widgets/order_card_skeleton.dart';

/// A full-page order detail screen for the store owner, reachable from
/// notification taps. Accepts an [orderId] and fetches the matching order
/// from the [StoreProvider].
class StoreOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const StoreOrderDetailScreen({super.key, required this.orderId});

  @override
  State<StoreOrderDetailScreen> createState() => _StoreOrderDetailScreenState();
}

class _StoreOrderDetailScreenState extends State<StoreOrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrder(showSkeleton: true));
  }

  Future<void> _loadOrder({bool showSkeleton = false}) async {
    if (showSkeleton) setState(() => _loading = true);
    try {
      final orders = await context.read<StoreProvider>().fetchStoreOrders();
      final match = orders.where((o) => o.id == widget.orderId).toList();
      if (!mounted) return;
      if (match.isNotEmpty) {
        setState(() {
          _order = match.first;
          _loading = false;
        });
      } else {
        setState(() {
          _error =
              'Order #...${widget.orderId.substring(widget.orderId.length > 6 ? widget.orderId.length - 6 : 0)} not found.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load order. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(
    String orderId,
    OrderStatus status, {
    String? rejectionReason,
  }) async {
    try {
      final provider = context.read<StoreProvider>();
      await provider.updateOrderStatus(
        orderId,
        status.backendName,
        rejectionReason: rejectionReason,
      );
      final updated = await provider.fetchStoreOrders();
      if (!mounted) return;
      final match = updated.where((o) => o.id == orderId).toList();
      if (match.isNotEmpty) {
        setState(() => _order = match.first);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated to ${status.displayLabel}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update order status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? OrderDetailSkeleton(isDark: isDark)
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: muted),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() { _loading = true; _error = null; });
                            _loadOrder();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  // Keep content visible on refresh — no full-page spinner
                  onRefresh: _loadOrder,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      OrderCard(
                        order: _order!,
                        isUpdating: false,
                        textColor: textColor,
                        muted: muted,
                        surface: surface,
                        border: border,
                        onUpdateStatus: _updateStatus,
                      ),
                    ],
                  ),
                ),
    );
  }
}
