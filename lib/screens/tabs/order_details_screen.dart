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
