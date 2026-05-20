import 'package:flutter/material.dart';

import 'package:campuschow/models/order.dart';
import 'package:campuschow/repositories/order_repository.dart';
import 'package:campuschow/widgets/orders/active_order_tracker.dart';
import 'package:campuschow/widgets/orders/order_receipt.dart';
import 'components/order_details_app_bar.dart';
import 'components/order_details_error.dart';

// ---------------------------------------------------------------------------
// OrderDetailsScreen
// ---------------------------------------------------------------------------

/// Displays the full receipt and live tracking for a single [Order].
///
/// Accepts either a fully-loaded [order] object or an [orderId] string.
/// When only [orderId] is supplied the screen fetches the order on mount.
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    this.order,
    this.orderId,
  }) : assert(
          order != null || orderId != null,
          'Provide at least one of order or orderId.',
        );

  final Order? order;
  final String? orderId;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  // ── State ──────────────────────────────────────────────────────────────────

  Order? _order;
  bool _isLoading = false;
  String? _error;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      // Order already loaded — no network call needed.
      _order = widget.order;
    } else {
      // orderId is guaranteed non-null by the assert above.
      _fetchOrder();
    }
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await OrderRepository().getOrderById(widget.orderId!);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load order details.';
        _isLoading = false;
      });
    }
  }

  // ── Derived state ──────────────────────────────────────────────────────────

  /// An order is "active" when it has not yet reached a terminal status.
  bool get _isActive =>
      _order != null &&
      _order!.status != OrderStatus.delivered &&
      _order!.status != OrderStatus.cancelled;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return const Scaffold(
        appBar: OrderDetailsAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error / not-found state
    if (_error != null || _order == null) {
      return Scaffold(
        appBar: const OrderDetailsAppBar(),
        body: OrderDetailsError(
          message: _error ?? 'Order not found.',
          onRetry: _fetchOrder,
        ),
      );
    }

    // Loaded state
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const OrderDetailsAppBar(),
      body: SingleChildScrollView(
        // ClampingScrollPhysics matches Android's native feel and, crucially,
        // does not let the scroll view compress itself — content always gets
        // its full intrinsic height, so nothing is clipped at the bottom.
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          // Add the bottom safe-area inset (notch / gesture bar) so the last
          // widget is never hidden behind the system UI.
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_order!.status == OrderStatus.priceAdjusted)
              PriceAdjustmentPanel(
                order: _order!,
                onUpdated: _fetchOrder,
              ),
            if (_isActive) ...[
              ActiveOrderTracker(order: _order!),
              const SizedBox(height: 32),
            ],
            OrderReceipt(order: _order!),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PriceAdjustmentPanel
// ---------------------------------------------------------------------------

class PriceAdjustmentPanel extends StatefulWidget {
  final Order order;
  final VoidCallback onUpdated;

  const PriceAdjustmentPanel({
    super.key,
    required this.order,
    required this.onUpdated,
  });

  @override
  State<PriceAdjustmentPanel> createState() => _PriceAdjustmentPanelState();
}

class _PriceAdjustmentPanelState extends State<PriceAdjustmentPanel> {
  bool _submitting = false;

  Future<void> _respond(String action) async {
    setState(() => _submitting = true);
    try {
      await OrderRepository().respondToPriceAdjustment(widget.order.id, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'ACCEPT'
              ? 'Price adjustment accepted. Processing order...'
              : 'Order cancelled successfully.'),
        ),
      );
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process response: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final original = widget.order.originalTotal ?? widget.order.total;
    final current = widget.order.total;
    final diff = current - original;

    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Price Adjustment Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'The store owner has updated the price of items in your order. Please review the updated pricing below:',
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Original Total:', style: TextStyle(color: Colors.black54)),
              Text('₦${original.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Updated Total:', style: TextStyle(color: Colors.black54)),
              Text('₦${current.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                diff > 0 ? 'Balance to Pay:' : 'Refund Amount:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: diff > 0 ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              Text(
                '₦${diff.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: diff > 0 ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_submitting)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _respond('REJECT'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond('ACCEPT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      diff > 0 ? 'Pay Balance' : 'Accept Refund',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
