import 'package:campuschow/constants/app_colors.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/orders/active_order_tracker.dart';
import '../../widgets/orders/order_receipt.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/checkout/widgets/payment_sheet.dart';
import 'components/order_details_app_bar.dart';
import 'components/order_details_error.dart';
import 'components/order_details_skeleton.dart';

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
  Order? _order;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      // Show whatever we already have immediately for snappy UX,
      // but ALWAYS refresh from the server so stale cached statuses
      // (e.g. "Ready for Pickup" after the order was actually delivered)
      // get corrected on open.
      _order = widget.order;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchOrder();
        // Also nudge the global order list so any other screens (home,
        // orders tab) reflect the latest status.
        if (mounted) {
          context.read<OrderProvider>().refreshOrders();
        }
      });
    } else {
      _fetchOrder();
    }
  }

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



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;

    // Loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: const OrderDetailsAppBar(),
        body: const OrderDetailsSkeleton(),
      );
    }

    // Watch the orders list in the provider to react to real-time status updates (via Ably/FCM)
    final orderProvider = context.watch<OrderProvider>();
    final orderId = widget.orderId ?? _order?.id ?? widget.order?.id;
    final providerOrder = orderProvider.orders.cast<Order?>().firstWhere(
          (o) => o?.id == orderId,
          orElse: () => null,
        );

    // Use the provider's order if available, otherwise fallback to local _order state
    final order = providerOrder ?? _order;
    
    // Debug log to investigate why panel might still be visible
    if (order != null) {
      debugPrint('[OrderDetails] Debug: ID=${order.id}, Status=${order.status}, isDelivered=${order.status == OrderStatus.delivered}');
    }

    // Error / not-found state
    if (_error != null || order == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: const OrderDetailsAppBar(),
        body: OrderDetailsError(
          message: _error ?? 'Order not found.',
          onRetry: _fetchOrder,
        ),
      );
    }

    final isPendingPayment = order.status == OrderStatus.pendingPayment;
    final isActive = order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;
    
    // Strict restriction
    final showPriceAdjustment = order.status == OrderStatus.priceAdjusted && order.status != OrderStatus.delivered;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: const OrderDetailsAppBar(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20.w,
          24.h,
          20.w,
          24.h + (isPendingPayment ? 0 : MediaQuery.paddingOf(context).bottom),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showPriceAdjustment)
              PriceAdjustmentPanel(order: order, onUpdated: _fetchOrder),
            if (order.status == OrderStatus.delivered)
              RateOrderPanel(order: order),
            if (isActive) ...[
              ActiveOrderTracker(order: order),
              if (order.status == OrderStatus.readyForPickup &&
                  (order.deliveryType.toLowerCase() == 'pickup' ||
                      order.deliveryType.toLowerCase() == 'store_pickup')) ...[
                SizedBox(height: 24.h),
                UpgradeToDeliveryPanel(order: order, onUpdated: _fetchOrder),
              ],
              SizedBox(height: 32.h),
            ],
            OrderReceipt(order: order),
          ],
        ),
      ),
      bottomNavigationBar: isPendingPayment
          ? _PendingPaymentBottomBar(
              order: order,
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
// RateOrderPanel
// ---------------------------------------------------------------------------

class RateOrderPanel extends StatefulWidget {
  final Order order;

  const RateOrderPanel({super.key, required this.order});

  @override
  State<RateOrderPanel> createState() => _RateOrderPanelState();
}

class _RateOrderPanelState extends State<RateOrderPanel> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  Future<void> _submitRating() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    
    try {
      // 1. Send Ably notification to store
      await ablyService.publishFeedback(
        storeId: widget.order.items.first.menuItem.storeId,
        orderId: widget.order.id,
        feedback: _feedbackController.text.trim(),
        rating: _rating,
      );
      
      // Simulate/Trigger rating API here...
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send feedback.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;
    
    final bg = isDark
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.05);
    final border = AppColors.primary.withValues(alpha: 0.3);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Text(
            'How was your meal?',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                onPressed: _submitting ? null : () => setState(() => _rating = starValue),
                icon: Icon(
                  starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: starValue <= _rating ? Colors.amber : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  size: 40.sp,
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            SizedBox(height: 12.h),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Any comments for the store?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? SizedBox(
                        height: 20.sp,
                        width: 20.sp,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ],
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
    debugPrint('[PriceAdjustmentPanel] Responding with: $action for orderId=${widget.order.id}, CurrentStatus=${widget.order.status}');
    if (widget.order.status == OrderStatus.delivered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot adjust price on completed order.'), backgroundColor: Colors.red),
      );
      return;
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;
    final original = widget.order.originalTotal ?? widget.order.total;
    final current = widget.order.total;
    final diff = current - original;
    final isHigher = diff > 0;

    // Amber-based warning colors adapted for light/dark
    final warningBg = isDark
        ? const Color(0x1AFFCA28) // amber with 10% alpha
        : const Color(0x26FFCA28); // amber with 15% alpha
    final warningBorder = const Color(0xFFFFCA28); // Amber 700
    final warningText = isDark
        ? const Color(0xFFFFD54F)
        : const Color(0xFF8D6E00);
    final warningIconColor = isDark
        ? const Color(0xFFFFD54F)
        : const Color(0xFF8D6E00);

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: warningBg,
        border: Border.all(color: warningBorder, width: 1.5),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: warningIconColor,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  isHigher ? 'Price Adjustment Required' : 'Price Reduced',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: warningText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            isHigher
                ? 'The store owner has increased the order price. Pay the balance to continue, or cancel the order.'
                : 'The store owner has reduced the order price. Accept the updated order to continue.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightText,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Original Total:',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightMuted,
                ),
              ),
              Text(
                '₦${original.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Updated Total:',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightMuted,
                ),
              ),
              Text(
                '₦${current.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(
            height: 16.h,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHigher ? 'Balance to Pay:' : 'Amount Reduced:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHigher ? Colors.red.shade400 : Colors.green.shade400,
                ),
              ),
              Text(
                '₦${diff.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: isHigher ? Colors.red.shade400 : Colors.green.shade400,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (_submitting)
            Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _respond('REJECT'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: const Text(
                      'Cancel Order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond('ACCEPT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isHigher ? 'Pay Balance' : 'Accept Order',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Cancel Order?',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this unpaid order? This action cannot be undone.',
          style: TextStyle(color: mutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No, Keep It', style: TextStyle(color: mutedColor)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + bottomInset),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _isLoading
          ? SizedBox(
              height: 48.h,
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelOrder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      'Cancel Order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showPaymentSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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

class UpgradeToDeliveryPanel extends StatefulWidget {
  final Order order;
  final VoidCallback onUpdated;

  const UpgradeToDeliveryPanel({
    super.key,
    required this.order,
    required this.onUpdated,
  });

  @override
  State<UpgradeToDeliveryPanel> createState() => _UpgradeToDeliveryPanelState();
}

class _UpgradeToDeliveryPanelState extends State<UpgradeToDeliveryPanel> {
  bool _submitting = false;

  Future<void> _upgradeWithWallet() async {
    setState(() => _submitting = true);
    try {
      HapticFeedback.mediumImpact();
      await OrderRepository().changeToDelivery(widget.order.id, 'Wallet');

      if (mounted) {
        final auth = context.read<AuthProvider>();
        await auth.refreshUser();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order upgraded to Delivery via wallet!'),
            backgroundColor: Colors.green,
          ),
        );
        context.read<OrderProvider>().refreshOrders();
        widget.onUpdated();
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _upgradeWithPaystack() async {
    setState(() => _submitting = true);
    try {
      HapticFeedback.mediumImpact();
      final auth = context.read<AuthProvider>();
      final email = auth.isAuthenticated
          ? (auth.user?.email ?? 'user@campuschow.com')
          : 'guest@campuschow.com';

      final paymentData = await OrderRepository().changeToDelivery(
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening Paystack payment page...')),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showPaymentSelection() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _upgradeWithPaystack();
      return;
    }

    final balance = auth.user?.walletBalance ?? 0.0;
    const total = 1300.0;
    final isInsufficient = balance < total;

    PaymentSheet.show(
      context: context,
      current: 'Paystack',
      balance: balance,
      total: total,
      isInsufficient: isInsufficient,
      onSelected: (method) {
        if (method == 'Wallet') {
          _upgradeWithWallet();
        } else {
          _upgradeWithPaystack();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;

    final warningBg = isDark
        ? const Color(0x1A00B0FF)
        : const Color(0x2600B0FF);
    final warningBorder = const Color(0xFF00B0FF);
    final warningText = isDark
        ? const Color(0xFF80D8FF)
        : const Color(0xFF0091EA);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: warningBg,
        border: Border.all(color: warningBorder, width: 1.5),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delivery_dining_rounded,
                color: warningText,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Switch to Delivery?',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: warningText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Too busy to pick it up? Have your order delivered to your location instead for a flat fee of ₦1,300.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightText,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              onPressed: _submitting ? null : _showPaymentSelection,
              child: _submitting
                  ? SizedBox(
                      width: 20.sp,
                      height: 20.sp,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Request Delivery (₦1,300 Fee)',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
