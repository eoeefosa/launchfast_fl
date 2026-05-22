import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'package:campuschow/models/order.dart';
import 'package:campuschow/repositories/order_repository.dart';
import 'package:campuschow/widgets/orders/active_order_tracker.dart';
import 'package:campuschow/widgets/orders/order_receipt.dart';
import 'package:campuschow/providers/order_provider.dart';
import 'package:campuschow/providers/auth_provider.dart';
import 'package:campuschow/screens/checkout/widgets/payment_sheet.dart';
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
  const OrderDetailsScreen({super.key, this.order, this.orderId})
    : assert(
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
      if (widget.orderId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOrder());
      }
    } else {
      // orderId is guaranteed non-null by the assert above.
      _fetchOrder();
    }
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchOrder() async {
    final orderId = widget.orderId ?? _order?.id ?? widget.order?.id;
    if (orderId == null) {
      setState(() {
        _error = 'Order not found.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await OrderRepository().getOrderById(orderId);
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

    final isPendingPayment = _order!.status == OrderStatus.pendingPayment;

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
          24 + (isPendingPayment ? 0 : MediaQuery.paddingOf(context).bottom),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_order!.status == OrderStatus.priceAdjusted)
              PriceAdjustmentPanel(order: _order!, onUpdated: _fetchOrder),
            if (_isActive) ...[
              ActiveOrderTracker(order: _order!),
              const SizedBox(height: 32),
            ],
            OrderReceipt(order: _order!),
          ],
        ),
      ),
      bottomNavigationBar: isPendingPayment
          ? _PendingPaymentBottomBar(
              order: _order!,
              onPaid: () {
                _fetchOrder();
                context.read<OrderProvider>().refreshOrders();
              },
              onCancelled: () {
                _fetchOrder();
                context.read<OrderProvider>().refreshOrders();
              },
            )
          : null,
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
      context.read<OrderProvider>().refreshOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'ACCEPT'
                ? 'Price adjustment accepted. Processing order...'
                : 'Order cancelled successfully.',
          ),
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
    final isHigher = diff > 0;

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
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade900,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isHigher ? 'Price Adjustment Required' : 'Price Reduced',
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
          Text(
            isHigher
                ? 'The store owner has increased the order price. Pay the balance to continue, or cancel the order.'
                : 'The store owner has reduced the order price. Accept the updated order to continue.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Original Total:',
                style: TextStyle(color: Colors.black54),
              ),
              Text(
                '₦${original.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Updated Total:',
                style: TextStyle(color: Colors.black54),
              ),
              Text(
                '₦${current.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHigher ? 'Balance to Pay:' : 'Amount Reduced:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHigher ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              Text(
                '₦${diff.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isHigher ? Colors.red.shade700 : Colors.green.shade700,
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
                    child: const Text(
                      'Cancel Order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isHigher ? 'Pay Balance' : 'Accept Order',
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

class _PendingPaymentBottomBar extends StatefulWidget {
  final Order order;
  final VoidCallback onPaid;
  final VoidCallback onCancelled;

  const _PendingPaymentBottomBar({
    required this.order,
    required this.onPaid,
    required this.onCancelled,
  });

  @override
  State<_PendingPaymentBottomBar> createState() =>
      _PendingPaymentBottomBarState();
}

class _PendingPaymentBottomBarState extends State<_PendingPaymentBottomBar> {
  bool _isLoading = false;

  Future<void> _payWithWallet() async {
    setState(() => _isLoading = true);
    try {
      HapticFeedback.mediumImpact();
      await OrderRepository().payWithWallet(widget.order.id);

      // Update local wallet balance
      if (mounted) {
        final auth = context.read<AuthProvider>();
        await auth.refreshUser();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order paid successfully via wallet!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPaid();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pay: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payWithPaystack() async {
    setState(() => _isLoading = true);
    try {
      HapticFeedback.mediumImpact();
      final auth = context.read<AuthProvider>();
      final email = auth.isAuthenticated
          ? (auth.user?.email ?? 'user@campuschow.com')
          : 'guest@campuschow.com';

      final paymentData = await OrderRepository().initializePayment(
        widget.order.id,
        'Card',
        email: email,
      );

      final authorizationUrl =
          (paymentData['data'] as Map<String, dynamic>?)?['authorization_url']
              as String?;

      if (authorizationUrl == null) {
        throw Exception('Payment initialization failed.');
      }

      final uri = Uri.parse(authorizationUrl);
      if (!await canLaunchUrl(uri)) {
        throw Exception('Could not open payment page.');
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Since it launches externally, we tell the user to complete payment
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening Paystack payment page...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentSelection() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      // Guest checkout -> directly paystack
      _payWithPaystack();
      return;
    }

    final balance = auth.user?.walletBalance ?? 0.0;
    final total = widget.order.total;
    final isInsufficient = balance < total;

    PaymentSheet.show(
      context: context,
      current: 'Paystack',
      balance: balance,
      total: total,
      isInsufficient: isInsufficient,
      onSelected: (method) {
        if (method == 'Wallet') {
          _payWithWallet();
        } else {
          _payWithPaystack();
        }
      },
      onInsufficientFunds: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient wallet funds. Please use Paystack.'),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Are you sure you want to cancel this unpaid order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      HapticFeedback.mediumImpact();
      await OrderRepository().updateOrder(widget.order.id, {
        'status': 'cancelled',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully.')),
        );
        widget.onCancelled();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _isLoading
          ? const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelOrder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel Order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showPaymentSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
