import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../theme/app_spacing.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import '../../widgets/home/location_selector.dart';

import 'widgets/success_view.dart';
import 'widgets/order_summary_section.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/insufficient_funds_dialog.dart';
import 'widgets/delivery_type_sheet.dart';
import 'widgets/payment_sheet.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryType _deliveryType = DeliveryType.bulk;
  bool _isSuccess = false;
  String _paymentMethod = 'Wallet';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.read<AuthProvider>();

    final total = cart.totalFor(_deliveryType);
    final hasQueuedItems = cart.items.any((i) => !i.menuItem.isReady);

    if (_isSuccess) return const SuccessView();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _appBar(),
              SliverToBoxAdapter(
                child: _sectionCard(
                  title: 'Deliver to',
                  child: const LocationSelector(),
                ),
              ),
              SliverToBoxAdapter(
                child: _sectionCard(
                  title: 'Delivery Type',
                  child: ListTile(
                    leading: _iconContainer(_iconForDeliveryType(_deliveryType)),
                    title: Text(_deliveryType.label),
                    subtitle: Text(_deliveryType.priceLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showDeliverySheet,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _sectionCard(
                  title: 'Payment',
                  child: _buildPaymentTile(auth, total),
                ),
              ),
              SliverToBoxAdapter(
                child: _sectionCard(
                  title: 'Order Summary',
                  child: OrderSummarySection(cart: cart, deliveryType: _deliveryType),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
          BottomBar(
            total: total,
            isLoading: orderProvider.isLoading,
            isWalletInsufficient: _paymentMethod == 'Wallet' && !auth.hasSufficientFunds(total),
            hasQueuedItems: hasQueuedItems,
            onPlaceOrder: () => _placeOrder(total, cart, orderProvider, auth, hasQueuedItems),
            onInsufficientFunds: () => _showInsufficientFundsDialog(auth.user?.walletBalance ?? 0, total),
          ),
        ],
      ),
    );
  }

  // ── Section builders ────────────────────────────────────────────────────────

  Widget _buildPaymentTile(AuthProvider auth, double total) {
    final balance = auth.user?.walletBalance ?? 0;
    final isInsufficient = _paymentMethod == 'Wallet' && !auth.hasSufficientFunds(total);

    return ListTile(
      leading: _iconContainer(
        _paymentMethod == 'Wallet'
            ? Icons.account_balance_wallet_rounded
            : Icons.payment_rounded,
        error: isInsufficient,
      ),
      title: Text(_paymentMethod),
      subtitle: _paymentMethod == 'Wallet'
          ? Text(
              'Balance: ₦${balance.toStringAsFixed(0)}',
              style: TextStyle(
                color: isInsufficient ? Colors.red : Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            )
          : const Text('Tap to change'),
      trailing: isInsufficient
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Low Balance',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => _showPaymentSheet(total),
    );
  }

  // ── Reusable widgets ────────────────────────────────────────────────────────

  IconData _iconForDeliveryType(DeliveryType type) {
    switch (type) {
      case DeliveryType.priority:
        return Icons.bolt_rounded;
      case DeliveryType.pickup:
        return Icons.store_rounded;
      case DeliveryType.bulk:
        return Icons.local_shipping_rounded;
    }
  }

  Widget _iconContainer(IconData icon, {bool error = false}) {
    final color = error ? Colors.red : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }

  SliverAppBar _appBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Review & Place Order',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppShadows.softCard],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            child,
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ── Sheets ──────────────────────────────────────────────────────────────────

  void _showDeliverySheet() {
    DeliveryTypeSheet.show(context, _deliveryType, (type) {
      setState(() => _deliveryType = type);
    });
  }

  void _showPaymentSheet(double total) {
    final auth = context.read<AuthProvider>();
    final balance = auth.user?.walletBalance ?? 0;
    final isInsufficient = !auth.hasSufficientFunds(total);

    PaymentSheet.show(
      context: context,
      current: _paymentMethod,
      balance: balance,
      total: total,
      isInsufficient: isInsufficient,
      onSelected: (method) {
        setState(() => _paymentMethod = method);
      },
      onInsufficientFunds: () => _showInsufficientFundsDialog(balance, total),
    );
  }

  void _showInsufficientFundsDialog(double balance, double total) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => InsufficientFundsDialog(
        balance: balance,
        total: total,
        onPayWithPaystack: () {
          Navigator.pop(dialogContext);
          setState(() => _paymentMethod = 'Paystack');
        },
      ),
    );
  }

  void _showErrorDialog(String message) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.error_outline_rounded,
          size: 44,
          color: Colors.red,
        ),
        title: const Text(
          'Something went wrong',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Order placement ─────────────────────────────────────────────────────────

  Future<void> _placeOrder(
    double total,
    CartProvider cart,
    OrderProvider orderProvider,
    AuthProvider auth,
    bool hasQueuedItems,
  ) async {
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }

    // Final wallet check — total is the grand total the user must pay.
    if (_paymentMethod == 'Wallet') {
      final balance = auth.user?.walletBalance ?? 0;
      if (!auth.hasSufficientFunds(total)) {
        _showInsufficientFundsDialog(balance, total);
        return;
      }
    }

    try {
      HapticFeedback.mediumImpact();

      // Only send the food subtotal — the backend recomputes service fee,
      // delivery fee, and grand total server-side so the client cannot lie.
      final subtotal = cart.subTotal;

      final orderData = {
        'items': cart.items.map((i) => {
          'menuItem':      {'id': i.menuItem.id},
          'quantity':      i.quantity,
          'extras':        i.extras,
          'selectedMeats': i.selectedMeats,
          'hasSalad':      i.hasSalad,
          'selectedAddons': i.selectedAddons,
        }).toList(),
        'subtotal':     subtotal,
        'deliveryType': _deliveryType.name,     // 'bulk' | 'priority' | 'pickup'
        'paymentMethod': _paymentMethod,
        'userId':        auth.user!.id,
        'stores':        cart.items.map((i) => i.menuItem.storeId).toSet().toList(),
      };

      final Order? success = await orderProvider.placeOrder(orderData);

      if (!mounted) return;

      if (success != null) {
        HapticFeedback.heavyImpact();
        // If wallet was used the backend already deducted; refresh local balance.
        if (_paymentMethod == 'Wallet') {
          await auth.refreshUser();
        }
        cart.clearCart();
        setState(() => _isSuccess = true);
      } else {
        _showErrorDialog(orderProvider.error ?? 'Your order could not be placed. Please try again.');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String message = 'An error occurred during checkout. Please try again.';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'The connection timed out. Please check your internet and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Could not connect to the server. Please check your internet.';
      } else if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? e.response?.data['error'] ?? message;
      }

      _showErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('An unexpected error occurred. Please try again.');
    }
  }
}
