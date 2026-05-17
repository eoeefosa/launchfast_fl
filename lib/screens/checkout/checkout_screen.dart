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
import 'widgets/checkout_dialogs.dart';
import 'widgets/checkout_guest_widgets.dart';
import 'widgets/checkout_scroll_body.dart';
import 'widgets/insufficient_funds_dialog.dart';
import 'widgets/phone_confirm_sheet.dart';
import 'widgets/success_view.dart';
import '../../widgets/home/location_selector.dart';

// ---------------------------------------------------------------------------
// Domain types
// ---------------------------------------------------------------------------

enum CheckoutPaymentMethod { wallet, paystack }

// ---------------------------------------------------------------------------
// CheckoutScreen
// ---------------------------------------------------------------------------

/// The checkout flow: delivery options, payment method selection,
/// order summary, and order placement (wallet or Paystack).
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

    // Defer provider reads until after the first frame so the widget tree is
    // fully built — required by Flutter's provider documentation.
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
    final hasGuestDetails =
        auth.guestName != null &&
        auth.guestPhone != null &&
        auth.currentAddress != null;

    if (!auth.isAuthenticated && !hasGuestDetails) {
      setState(() => _isGuestCheckout = true);
    }
  }

  // ── Derived helpers ────────────────────────────────────────────────────────

  bool _hasQueuedItems(CartProvider cart) =>
      cart.items.any((item) => !item.menuItem.isReady);

  bool _isWalletInsufficient(AuthProvider auth, double total) =>
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
          CheckoutScrollBody(
            auth: auth,
            cart: cart,
            deliveryType: _deliveryType,
            paymentMethod: _paymentMethod,
            isGuestCheckout: _isGuestCheckout,
            guestNameController: _guestNameController,
            guestPhoneController: _guestPhoneController,
            total: total,
            onDeliveryTypeChanged: (type) =>
                setState(() => _deliveryType = type),
            onPaymentMethodChanged: (method) =>
                setState(() => _paymentMethod = method),
            onGuestContinue: _onGuestContinue,
            onShowError: _showErrorDialog,
            onFundWallet: () => _showInsufficientFundsDialog(
              auth.user?.walletBalance ?? 0,
              total,
            ),
          ),
          BottomBar(
            total: total,
            isLoading: orderProvider.isLoading,
            hasQueuedItems: _hasQueuedItems(cart),
            isWalletInsufficient: _isWalletInsufficient(auth, total),
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
          name: _guestNameController.text.trim(),
          phone: _guestPhoneController.text.trim(),
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

  /// Prompts the guest to enter/confirm their contact details before ordering.
  /// Returns `true` if the user saved valid information, `false` if cancelled.
  Future<bool> _showGuestContactDialog(AuthProvider auth) async {
    final nameController = TextEditingController(text: auth.guestName ?? '');
    final phoneController = TextEditingController(text: auth.guestPhone ?? '');

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GuestContactDialog(
        nameController: nameController,
        phoneController: phoneController,
      ),
    );

    if (saved != true) return false;

    auth.setGuestInfo(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
    );
    // Mirror into the inline form controllers so they stay in sync.
    _guestNameController.text = nameController.text.trim();
    _guestPhoneController.text = phoneController.text.trim();
    setState(() => _isGuestCheckout = false);
    return true;
  }

  void _showInsufficientFundsDialog(double balance, double total) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => InsufficientFundsDialog(
        balance: balance,
        total: total,
        onPayWithPaystack: () {
          Navigator.of(dialogContext).pop();
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
    // 1. Validate swallow items have a soup selected.
    final hasSwallowWithoutSoup = cart.items.any(
      (item) =>
          (item.menuItem.type == 'swallow' ||
              item.menuItem.category == 'Swallow' ||
              item.menuItem.requiresSoupSelection) &&
          (item.selectedSoup == null || item.selectedSoup!['id'] == null),
    );
    if (hasSwallowWithoutSoup) {
      _showErrorDialog(
        'A soup selection is required for your Swallow items before ordering.',
      );
      return;
    }

    // 2. Ensure guest has contact details.
    if (!auth.isAuthenticated) {
      final hasContact =
          (auth.guestName?.isNotEmpty ?? false) &&
          (auth.guestPhone?.isNotEmpty ?? false);
      if (!hasContact) {
        final saved = await _showGuestContactDialog(auth);
        if (!saved) return;
      }
    }

    // 3. Ensure a delivery address is set.
    if (!mounted) return;
    if (auth.currentAddress?.trim().isEmpty ?? true) {
      LocationSelector.show(context);
      return;
    }

    // 4. Confirm / update the phone number.
    final rawPhone = auth.isAuthenticated
        ? (auth.user?.phone ?? auth.guestPhone ?? '')
        : (auth.guestPhone ?? '');

    final confirmedPhone = await PhoneConfirmSheet.show(
      context,
      currentPhone: rawPhone.trim().isEmpty ? null : rawPhone.trim(),
    );
    if (!mounted || confirmedPhone == null) return;

    // 5. Re-check wallet balance at submission time.
    if (_paymentMethod == CheckoutPaymentMethod.wallet &&
        !auth.hasSufficientFunds(total)) {
      _showInsufficientFundsDialog(auth.user?.walletBalance ?? 0, total);
      return;
    }

    // 6. Submit.
    try {
      HapticFeedback.mediumImpact();

      final orderPayload = _buildOrderPayload(
        cart: cart,
        auth: auth,
        confirmedPhone: confirmedPhone,
      );

      final Order? order = await orderProvider.placeOrder(orderPayload);
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

      // Wallet payment succeeded.
      await auth.refreshUser();
      cart.clearCart();
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _isSuccess = true);
    } on DioException catch (e) {
      if (!mounted) return;
      _showErrorDialog(_messageFromDioException(e));
    } catch (_) {
      if (!mounted) return;
      _showErrorDialog('An unexpected error occurred.');
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

    if (!mounted) return;

    final authorizationUrl =
        (paymentData['data'] as Map<String, dynamic>?)?['authorization_url']
            as String?;

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

  // ── Private helpers ────────────────────────────────────────────────────────

  Map<String, dynamic> _buildOrderPayload({
    required CartProvider cart,
    required AuthProvider auth,
    required String confirmedPhone,
  }) {
    final storeIds =
        cart.items.map((i) => i.menuItem.storeId).toSet().toList();
    final name = auth.isAuthenticated
        ? (auth.user?.name ?? '')
        : (auth.guestName ?? '');
    final email = auth.isAuthenticated
        ? (auth.user?.email ?? 'user@campuschow.com')
        : 'guest@campuschow.com';

    return {
      'items': [
        for (final item in cart.items)
          {
            'menuItemId': item.menuItem.id,
            'quantity': item.quantity,
            'extras': item.extras,
            'selectedMeats': item.selectedMeats,
            'selectedSides': item.selectedSides,
            'selectedDrinks': item.selectedDrinks,
            'selectedAddons': item.selectedAddons,
            if (item.selectedSoup != null) 'selectedSoup': item.selectedSoup,
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

  /// Maps a [DioException] to a user-readable message using Dart's exhaustive
  /// switch expression (introduced in Dart 3).
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
