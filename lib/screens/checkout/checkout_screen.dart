import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/checkout_app_bar.dart';
import 'widgets/checkout_dialogs.dart';
import 'widgets/checkout_guest_widgets.dart';
import 'widgets/checkout_payment_delivery.dart';
import 'widgets/checkout_section.dart';
import 'widgets/insufficient_funds_dialog.dart';
import 'widgets/order_summary_section.dart';
import 'widgets/phone_confirm_sheet.dart';
import 'widgets/success_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain types
// ─────────────────────────────────────────────────────────────────────────────

enum CheckoutPaymentMethod { wallet, paystack }

// ─────────────────────────────────────────────────────────────────────────────
// CheckoutScreen
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  DeliveryType _deliveryType = DeliveryType.priority;
  CheckoutPaymentMethod _paymentMethod = CheckoutPaymentMethod.paystack;
  bool _isSuccess = false;
  bool _isGuestCheckout = false;

  // ── Controllers ────────────────────────────────────────────────────────────
  late final TextEditingController _guestNameController;
  late final TextEditingController _guestPhoneController;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController();
    _guestPhoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveGuestState());
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  // ── Guest resolution ───────────────────────────────────────────────────────

  void _resolveGuestState() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final hasGuestDetails = auth.guestName != null &&
        auth.guestPhone != null &&
        auth.currentAddress != null;

    if (!auth.isAuthenticated && !hasGuestDetails) {
      setState(() => _isGuestCheckout = true);
    }
  }

  // ── Derived helpers ────────────────────────────────────────────────────────

  bool _hasQueuedItems(CartProvider cart) =>
      cart.items.any((item) => !item.menuItem.isReady);

  bool _walletInsufficient(AuthProvider auth, double total) =>
      _paymentMethod == CheckoutPaymentMethod.wallet &&
      !auth.hasSufficientFunds(total);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return const SuccessView();

    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final total = cart.totalFor(_deliveryType);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: CheckoutAppBar()),
              SliverToBoxAdapter(
                child: CheckoutSection(
                  title: 'DELIVERY ADDRESS',
                  child: GuestAddressTile(auth: auth),
                ),
              ),
              if (_isGuestCheckout)
                SliverToBoxAdapter(
                  child: CheckoutSection(
                    title: 'CONTACT DETAILS',
                    child: GuestContactForm(
                      nameController: _guestNameController,
                      phoneController: _guestPhoneController,
                      onContinue: _onGuestContinue,
                      onError: _showErrorDialog,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: CheckoutSection(
                  title: 'DELIVERY OPTION',
                  child: DeliveryOptions(
                    cart: cart,
                    selected: _deliveryType,
                    onChanged: (t) => setState(() => _deliveryType = t),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CheckoutSection(
                  title: 'PAYMENT METHOD',
                  child: PaymentOptions(
                    auth: auth,
                    total: total,
                    selected: _paymentMethod,
                    onChanged: (m) => setState(() => _paymentMethod = m),
                    onFundWallet: () => _showInsufficientFundsDialog(
                      auth.user?.walletBalance ?? 0,
                      total,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CheckoutSection(
                  title: 'ORDER SUMMARY',
                  child: OrderSummarySection(
                    cart: cart,
                    deliveryType: _deliveryType,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),
          BottomBar(
            total: total,
            isLoading: orderProvider.isLoading,
            hasQueuedItems: _hasQueuedItems(cart),
            isWalletInsufficient: _walletInsufficient(auth, total),
            onPlaceOrder: () => _placeOrder(
              total: total,
              cart: cart,
              orderProvider: orderProvider,
              auth: auth,
            ),
            onInsufficientFunds: () => _showInsufficientFundsDialog(
              auth.user?.walletBalance ?? 0,
              total,
            ),
          ),
        ],
      ),
    );
  }

  // ── Guest form submit ──────────────────────────────────────────────────────

  void _onGuestContinue() {
    context.read<AuthProvider>().setGuestInfo(
          name: _guestNameController.text,
          phone: _guestPhoneController.text,
        );
    setState(() => _isGuestCheckout = false);
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showErrorDialog(String message) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      builder: (_) => CheckoutErrorDialog(message: message),
    );
  }

  void _showInsufficientFundsDialog(double balance, double total) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => InsufficientFundsDialog(
        balance: balance,
        total: total,
        onPayWithPaystack: () {
          Navigator.pop(ctx);
          setState(() => _paymentMethod = CheckoutPaymentMethod.paystack);
        },
      ),
    );
  }

  // ── Place order ────────────────────────────────────────────────────────────

  Future<void> _placeOrder({
    required double total,
    required CartProvider cart,
    required OrderProvider orderProvider,
    required AuthProvider auth,
  }) async {
    if (!auth.isAuthenticated) {
      final nameOk = auth.guestName?.isNotEmpty ?? false;
      final phoneOk = auth.guestPhone?.isNotEmpty ?? false;
      if (!nameOk || !phoneOk) {
        setState(() => _isGuestCheckout = true);
        _showErrorDialog('Please provide your contact information.');
        return;
      }
    }

    if (auth.currentAddress?.trim().isEmpty ?? true) {
      _showErrorDialog('Please set a delivery location.');
      return;
    }

    final rawPhone = auth.isAuthenticated
        ? (auth.user?.phone ?? auth.guestPhone ?? '')
        : (auth.guestPhone ?? '');

    final confirmedPhone = await PhoneConfirmSheet.show(
      context,
      currentPhone: rawPhone.trim().isEmpty ? null : rawPhone.trim(),
    );

    if (!mounted || confirmedPhone == null) return;

    if (_paymentMethod == CheckoutPaymentMethod.wallet &&
        !auth.hasSufficientFunds(total)) {
      _showInsufficientFundsDialog(auth.user?.walletBalance ?? 0, total);
      return;
    }

    try {
      HapticFeedback.mediumImpact();

      final orderData = _buildOrderPayload(
        cart: cart,
        auth: auth,
        confirmedPhone: confirmedPhone,
      );

      final Order? order = await orderProvider.placeOrder(orderData);

      if (!mounted) return;

      if (order == null) {
        _showErrorDialog(orderProvider.error ?? 'Could not place order.');
        return;
      }

      if (_paymentMethod == CheckoutPaymentMethod.paystack) {
        await _handlePaystackPayment(
          orderId: order.id,
          auth: auth,
          cart: cart,
          orderProvider: orderProvider,
        );
        return;
      }

      await auth.refreshUser();
      cart.clearCart();
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _isSuccess = true);
    } on DioException catch (e) {
      if (!mounted) return;
      _showErrorDialog(_messageFromDioException(e));
    } catch (_) {
      if (!mounted) return;
      _showErrorDialog('Unexpected error occurred.');
    }
  }

  Future<void> _handlePaystackPayment({
    required String orderId,
    required AuthProvider auth,
    required CartProvider cart,
    required OrderProvider orderProvider,
  }) async {
    final email = auth.isAuthenticated
        ? (auth.user?.email ?? 'user@campuschow.com')
        : 'guest@campuschow.com';

    final paymentData = await orderProvider.initializePayment(
      orderId,
      'Card',
      email: email,
    );

    final authorizationUrl =
        (paymentData['data'] as Map<String, dynamic>?)?['authorization_url']
            as String?;

    if (!mounted) return;

    if (authorizationUrl == null) {
      _showErrorDialog('Payment initialization failed.');
      return;
    }

    final uri = Uri.parse(authorizationUrl);
    if (!await canLaunchUrl(uri)) {
      if (mounted) _showErrorDialog('Could not open payment page.');
      return;
    }

    cart.clearCart();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted) context.pop();
  }

  Map<String, dynamic> _buildOrderPayload({
    required CartProvider cart,
    required AuthProvider auth,
    required String confirmedPhone,
  }) {
    final storeIds = cart.items.map((i) => i.menuItem.storeId).toSet().toList();
    final name = auth.isAuthenticated
        ? (auth.user?.name ?? '')
        : (auth.guestName ?? '');
    final email = auth.isAuthenticated
        ? (auth.user?.email ?? 'user@campuschow.com')
        : 'guest@campuschow.com';

    return {
      'items': [
        for (final i in cart.items)
          {
            'menuItemId': i.menuItem.id,
            'quantity': i.quantity,
            'extras': i.extras,
            'selectedMeats': i.selectedMeats,
            'selectedSides': i.selectedSides,
            'selectedDrinks': i.selectedDrinks,
            'selectedAddons': i.selectedAddons,
            if (i.selectedSoup != null) 'selectedSoup': i.selectedSoup,
          },
      ],
      'subtotal': cart.subTotal,
      'deliveryFee': cart.deliveryChargeFor(_deliveryType),
      'serviceFee': cart.serviceFees,
      'deliveryType': _deliveryType.name,
      'paymentMethod':
          _paymentMethod == CheckoutPaymentMethod.wallet ? 'Wallet' : 'Paystack',
      'userId': auth.user?.id,
      'customerDetails': {
        'name': name,
        'phone': confirmedPhone,
        'email': email,
        'address': auth.currentAddress ?? '',
      },
      'deliveryAddress': auth.currentAddress,
      'stores': storeIds,
      'restaurantIds': storeIds,
      'restaurantId': storeIds.isNotEmpty ? storeIds.first : null,
      'storeId': storeIds.isNotEmpty ? storeIds.first : null,
    };
  }

  static String _messageFromDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timeout. Please try again.',
      DioExceptionType.connectionError => 'No internet connection.',
      _ => (e.response?.data is Map
              ? e.response?.data['message'] as String?
              : null) ??
          'An error occurred during checkout.',
    };
  }
}
