import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../widgets/home/location_selector.dart';

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

    if (_isSuccess) return _successView(context);

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
                  child: _buildOrderSummary(cart),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
          _bottomBar(total, cart, orderProvider, auth, hasQueuedItems),
        ],
      ),
    );
  }

  // ── Success Screen ──────────────────────────────────────────────────────────

  Widget _successView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your food is being prepared 🍽️',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            FilledButton.tonal(
              onPressed: () => context.go('/'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('Back to Home'),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
      ),
    );
  }

  // ── Section builders ────────────────────────────────────────────────────────

  Widget _buildPaymentTile(AuthProvider auth, double total) {
    final balance = auth.user?.walletBalance ?? 0;
    final isInsufficient = _paymentMethod == 'Wallet' && balance < total;

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

  Widget _buildOrderSummary(CartProvider cart) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Text('${cart.totalQuantity} Items'),
      children: [
        ...cart.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.menuItem.name}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text('₦${item.totalPrice.toStringAsFixed(0)}'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 4),
        _row('Subtotal', cart.subTotal),
        _row('Service Charge', cart.serviceFees),
        _row('Delivery Charge', _deliveryType.charge,
            valueLabel: _deliveryType.charge == 0 ? 'FREE' : null),
      ],
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
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 6),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
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

  Widget _row(String label, double value, {String? valueLabel}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            valueLabel ?? '₦${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueLabel == 'FREE' ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sheets ──────────────────────────────────────────────────────────────────

  void _showDeliverySheet() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => _SelectionDialog(
        title: 'Delivery Type',
        options: [
          _option(
            DeliveryType.bulk,
            '₦300 • Wait for nearby packages',
          ),
          _option(
            DeliveryType.priority,
            '₦1,300 • Processed immediately',
          ),
          _option(
            DeliveryType.pickup,
            'FREE • Collect from the store',
          ),
        ],
      ),
    );
  }

  _SelectionOption _option(DeliveryType type, String subtitle) {
    return _SelectionOption(
      title: type.label,
      subtitle: subtitle,
      icon: _iconForDeliveryType(type),
      isSelected: _deliveryType == type,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _deliveryType = type);
        Navigator.pop(context);
      },
    );
  }

  void _showPaymentSheet(double total) {
    final auth = context.read<AuthProvider>();
    final balance = auth.user?.walletBalance ?? 0;
    final cart = context.read<CartProvider>();
    final total = cart.totalFor(_deliveryType);
    final isInsufficient = balance < total;
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => _SelectionDialog(
        title: 'Payment Method',
        subtitle: isInsufficient && _paymentMethod == 'Wallet'
            ? 'Your wallet balance is insufficient for this order'
            : null,
        options: [
          _SelectionOption(
            title: 'Wallet',
            subtitle: 'Balance: ₦${balance.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_rounded,
            isSelected: _paymentMethod == 'Wallet',
            isError: isInsufficient,
            onTap: () {
              if (isInsufficient) {
                Navigator.pop(context);
                _showInsufficientFundsDialog(balance, total);
              } else {
                HapticFeedback.selectionClick();
                setState(() => _paymentMethod = 'Wallet');
                Navigator.pop(context);
              }
            },
          ),
          _SelectionOption(
            title: 'Paystack',
            subtitle: 'Pay securely via card or transfer',
            icon: Icons.payment_rounded,
            isSelected: _paymentMethod == 'Paystack',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _paymentMethod = 'Paystack');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showInsufficientFundsDialog(double balance, double total) {
    final shortfall = total - balance;
    // Capture the screen's context BEFORE entering the dialog builder.
    // Inside builder(context), 'context' refers to the dialog's own context.
    // After Navigator.pop() destroys the dialog, that context is invalid —
    // using it for navigation throws an AssertionError.
    final screenContext = context;
    HapticFeedback.mediumImpact();
    showDialog(
      context: screenContext,
      builder: (dialogContext) =>
          Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(screenContext).colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 44,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Insufficient Balance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You need ₦${shortfall.toStringAsFixed(0)} more to complete this order.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            screenContext,
                          ).colorScheme.onSurface.withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _FundsRow(
                        label: 'Your Balance',
                        value: '₦${balance.toStringAsFixed(0)}',
                        color: Colors.red,
                      ),
                      _FundsRow(
                        label: 'Order Total',
                        value: '₦${total.toStringAsFixed(0)}',
                        color: Theme.of(screenContext).colorScheme.onSurface,
                      ),
                      _FundsRow(
                        label: 'Top-up Needed',
                        value: '₦${shortfall.toStringAsFixed(0)}',
                        color: Colors.orange,
                        bold: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            // Pop with dialogContext, navigate with screenContext.
                            Navigator.pop(dialogContext);
                            screenContext.push('/profile');
                          },
                          child: const Text(
                            'Top Up Wallet',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          setState(() => _paymentMethod = 'Paystack');
                        },
                        child: const Text('Pay with Paystack instead'),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
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

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _bottomBar(
    double total,
    CartProvider cart,
    OrderProvider orderProvider,
    AuthProvider auth,
    bool hasQueuedItems,
  ) {
    final balance = auth.user?.walletBalance ?? 0;
    final isWalletInsufficient = _paymentMethod == 'Wallet' && balance < total;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              spreadRadius: -4,
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                        '₦${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate(key: ValueKey(total))
                      .scale(begin: const Offset(0.95, 0.95)),
                ],
              ),
            ),
            GestureDetector(
              onTap: (orderProvider.isLoading || isWalletInsufficient)
                  ? (isWalletInsufficient
                        ? () => _showInsufficientFundsDialog(balance, total)
                        : null)
                  : () => _placeOrder(
                      total,
                      cart,
                      orderProvider,
                      auth,
                      hasQueuedItems,
                    ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: isWalletInsufficient
                      ? null
                      : LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                  color: isWalletInsufficient
                      ? Colors.red.withValues(alpha: 0.12)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: orderProvider.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isWalletInsufficient) ...[
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Top Up Required',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else
                            Text(
                              hasQueuedItems ? 'Join Queue' : 'Place Order',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
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

    // Final wallet check
    if (_paymentMethod == 'Wallet') {
      final balance = auth.user?.walletBalance ?? 0;
      if (balance < total) {
        _showInsufficientFundsDialog(balance, total);
        return;
      }
    }

    try {
      HapticFeedback.mediumImpact();
      final orderData = {
        'items': cart.items.map((i) => i.toJson()).toList(),
        'total': total,
        'deliveryType': _deliveryType.name,
        'paymentMethod': _paymentMethod,
        'userId': auth.user!.id,
      };

      final Order? success = await orderProvider.placeOrder(orderData);

      if (!mounted) return;

      if (success != null) {
        HapticFeedback.heavyImpact();
        cart.clearCart();
        setState(() => _isSuccess = true);
      } else {
        _showErrorDialog('Your order could not be placed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        'An unexpected error occurred. Please check your connection and try again.',
      );
    }
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────────

class _FundsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _FundsRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<_SelectionOption> options;

  const _SelectionDialog({
    required this.title,
    required this.options,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ...options.indexed.map(
                  (e) => e.$2
                      .animate(delay: (e.$1 * 80).ms)
                      .fadeIn()
                      .slideY(begin: 0.1),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 180.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }
}

class _SelectionOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isError;
  final VoidCallback onTap;

  const _SelectionOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final activeColor = isError ? Colors.red : primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? activeColor.withValues(alpha: 0.06)
            : isError
            ? Colors.red.withValues(alpha: 0.03)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : isError
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isError && !isSelected ? Icons.warning_amber_rounded : icon,
                    color: isSelected
                        ? Colors.white
                        : isError
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurface,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isSelected
                              ? activeColor
                              : isError
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.75)
                              : isError
                              ? Colors.red.withValues(alpha: 0.75)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: activeColor)
                else if (isError)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.red,
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
