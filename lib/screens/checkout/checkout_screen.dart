import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import '../../widgets/home/location_selector.dart';

import 'widgets/success_view.dart';
import 'widgets/order_summary_section.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/insufficient_funds_dialog.dart';
import 'widgets/phone_confirm_sheet.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum CheckoutPaymentMethod { wallet, paystack }

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  DeliveryType _deliveryType = DeliveryType.priority;
  CheckoutPaymentMethod _paymentMethod = CheckoutPaymentMethod.paystack;

  bool _isSuccess = false;

  // ───────────────── Guest Checkout ─────────────────

  bool _isGuestCheckout = false;

  final TextEditingController _guestNameController = TextEditingController();

  final TextEditingController _guestPhoneController = TextEditingController();

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.read<AuthProvider>();

    final total = cart.totalFor(_deliveryType);

    final bool hasQueuedItems = cart.items.any(
      (item) => !item.menuItem.isReady,
    );

    final bool hasGuestDetails =
        auth.guestName != null &&
        auth.guestPhone != null &&
        auth.currentAddress != null;

    if (!auth.isAuthenticated && !hasGuestDetails && !_isGuestCheckout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isGuestCheckout = true);
      });
    }

    if (_isSuccess) {
      return const SuccessView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),

              // ───────────────── Address ─────────────────
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'DELIVERY ADDRESS',
                  child: _isGuestCheckout
                      ? _buildGuestAddress(auth)
                      : const LocationSelector(),
                ),
              ),

              // ───────────────── Guest Contact ─────────────────
              if (_isGuestCheckout)
                SliverToBoxAdapter(
                  child: _buildSection(
                    title: 'CONTACT DETAILS',
                    child: _buildGuestContactForm(),
                  ),
                ),

              // ───────────────── Delivery Type ─────────────────
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'DELIVERY OPTION',
                  child: _buildDeliveryTabs(),
                ),
              ),

              // ───────────────── Payment ─────────────────
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'PAYMENT METHOD',
                  child: _buildPaymentTabs(auth, total),
                ),
              ),

              // ───────────────── Summary ─────────────────
              SliverToBoxAdapter(
                child: _buildSection(
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

          // ───────────────── Bottom Bar ─────────────────
          BottomBar(
            total: total,
            isLoading: orderProvider.isLoading,
            hasQueuedItems: hasQueuedItems,
            isWalletInsufficient:
                _paymentMethod == CheckoutPaymentMethod.wallet &&
                !auth.hasSufficientFunds(total),
            onPlaceOrder: () =>
                _placeOrder(total, cart, orderProvider, auth, hasQueuedItems),
            onInsufficientFunds: () => _showInsufficientFundsDialog(
              auth.user?.walletBalance ?? 0,
              total,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFFF6F7FB),
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      title: const Text(
        'Checkout',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION
  // ─────────────────────────────────────────────────────────────

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: .04),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 18),

              child,
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DELIVERY TABS
  // ─────────────────────────────────────────────────────────────

  Widget _buildDeliveryTabs() {
    return Column(
      children: [
        _optionTile(
          title: 'Priority Delivery',
          subtitle: 'Fast delivery to your location',
          trailingText: DeliveryType.priority.priceLabel,
          icon: Icons.flash_on_rounded,
          active: _deliveryType == DeliveryType.priority,
          onTap: () {
            setState(() {
              _deliveryType = DeliveryType.priority;
            });
          },
        ),
        const SizedBox(height: 10),
        _optionTile(
          title: 'Store Pickup',
          subtitle: 'Pick up your order yourself',
          trailingText: DeliveryType.pickup.priceLabel,
          icon: Icons.storefront_rounded,
          active: _deliveryType == DeliveryType.pickup,
          onTap: () {
            setState(() {
              _deliveryType = DeliveryType.pickup;
            });
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PAYMENT TABS
  // ─────────────────────────────────────────────────────────────

  Widget _buildPaymentTabs(AuthProvider auth, double total) {
    final balance = auth.user?.walletBalance ?? 0;
    final bool insufficient = !auth.hasSufficientFunds(total);

    return Column(
      children: [
        _optionTile(
          title: 'Wallet',
          subtitle: 'Balance: ₦${balance.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          active: _paymentMethod == CheckoutPaymentMethod.wallet,
          error: insufficient,
          onTap: () {
            setState(() {
              _paymentMethod = CheckoutPaymentMethod.wallet;
            });
          },
        ),
        const SizedBox(height: 10),
        _optionTile(
          title: 'Paystack',
          subtitle: 'Card • Transfer • USSD',
          icon: Icons.credit_card_rounded,
          active: _paymentMethod == CheckoutPaymentMethod.paystack,
          onTap: () {
            setState(() {
              _paymentMethod = CheckoutPaymentMethod.paystack;
            });
          },
        ),

        if (_paymentMethod == CheckoutPaymentMethod.wallet && insufficient) ...[
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Insufficient wallet balance for this order.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showInsufficientFundsDialog(balance, total),
                  child: const Text('Fund'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _optionTile({
    required String title,
    required String subtitle,
    String? trailingText,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    bool error = false,
  }) {
    final primary = error ? Colors.red : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? primary : Colors.grey.shade200,
            width: active ? 1.5 : 1,
          ),
          color: active ? primary.withValues(alpha: 0.06) : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: active ? primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: active ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : Colors.black87,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: error ? Colors.red : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: error ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: active ? primary : Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GUEST ADDRESS
  // ─────────────────────────────────────────────────────────────

  Widget _buildGuestAddress(AuthProvider auth) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => LocationSelector.show(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.currentAddress ?? 'Set delivery address',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Tap to select location',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GUEST FORM
  // ─────────────────────────────────────────────────────────────

  Widget _buildGuestContactForm() {
    return Column(
      children: [
        TextField(
          controller: _guestNameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Full name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),

        const SizedBox(height: 18),

        TextField(
          controller: _guestPhoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Phone number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),

        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              if (_guestNameController.text.isEmpty ||
                  _guestPhoneController.text.isEmpty) {
                _showErrorDialog(
                  'Please enter your full name and phone number.',
                );
                return;
              }

              context.read<AuthProvider>().setGuestInfo(
                name: _guestNameController.text,
                phone: _guestPhoneController.text,
              );

              setState(() {
                _isGuestCheckout = false;
              });
            },
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ERROR DIALOG
  // ─────────────────────────────────────────────────────────────

  void _showErrorDialog(String message) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 42,
          ),
          title: const Text(
            'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WALLET DIALOG
  // ─────────────────────────────────────────────────────────────

  void _showInsufficientFundsDialog(double balance, double total) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return InsufficientFundsDialog(
          balance: balance,
          total: total,
          onPayWithPaystack: () {
            Navigator.pop(dialogContext);

            setState(() {
              _paymentMethod = CheckoutPaymentMethod.paystack;
            });
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PLACE ORDER
  // ─────────────────────────────────────────────────────────────

  Future<void> _placeOrder(
    double total,
    CartProvider cart,
    OrderProvider orderProvider,
    AuthProvider auth,
    bool hasQueuedItems,
  ) async {
    if (!auth.isAuthenticated) {
      if (!auth.guestName.isNotNullOrEmpty() ||
          !auth.guestPhone.isNotNullOrEmpty()) {
        setState(() => _isGuestCheckout = true);

        _showErrorDialog('Please provide your contact information.');

        return;
      }
    }

    if (auth.currentAddress == null || auth.currentAddress!.trim().isEmpty) {
      _showErrorDialog('Please set a delivery location.');

      return;
    }

    final currentPhone = auth.isAuthenticated
        ? (auth.user?.phone ?? auth.guestPhone ?? '')
        : (auth.guestPhone ?? '');

    final confirmedPhone = await PhoneConfirmSheet.show(
      context,
      currentPhone: currentPhone.trim().isEmpty ? null : currentPhone.trim(),
    );

    if (!mounted) return;

    if (confirmedPhone == null) return;

    if (_paymentMethod == CheckoutPaymentMethod.wallet) {
      if (!auth.hasSufficientFunds(total)) {
        _showInsufficientFundsDialog(auth.user?.walletBalance ?? 0, total);

        return;
      }
    }

    try {
      HapticFeedback.mediumImpact();

      final subtotal = cart.subTotal;

      final orderData = {
        'items': cart.items
            .map(
              (i) => {
                'menuItemId': i.menuItem.id,
                'quantity': i.quantity,
                'extras': i.extras,
                'selectedMeats': i.selectedMeats,
                'hasSalad': i.hasSalad,
                'selectedAddons': i.selectedAddons,
                if (i.selectedSoup != null) 'selectedSoup': i.selectedSoup,
              },
            )
            .toList(),

        'subtotal': subtotal,

        'deliveryType': _deliveryType.name,

        'paymentMethod': _paymentMethod == CheckoutPaymentMethod.wallet
            ? 'Wallet'
            : 'Paystack',

        'userId': auth.user?.id,

        'customerDetails': {
          'name': auth.isAuthenticated
              ? (auth.user?.name ?? '')
              : (auth.guestName ?? ''),
          'phone': confirmedPhone,
          'email': auth.isAuthenticated
              ? (auth.user?.email ?? 'user@campuschow.com')
              : 'guest@campuschow.com',
          'address': auth.currentAddress ?? '',
        },

        'deliveryAddress': auth.currentAddress,

        'stores': cart.items.map((i) => i.menuItem.storeId).toSet().toList(),
      };

      final Order? success = await orderProvider.placeOrder(orderData);

      if (!mounted) return;

      if (success == null) {
        _showErrorDialog(orderProvider.error ?? 'Could not place order.');

        return;
      }

      // ───────────────── Paystack ─────────────────

      if (_paymentMethod == CheckoutPaymentMethod.paystack) {
        final customerEmail = auth.isAuthenticated
            ? (auth.user?.email ?? 'user@campuschow.com')
            : 'guest@campuschow.com';

        final paymentData = await orderProvider.initializePayment(
          success.id,
          'Card',
          email: customerEmail,
        );

        final paystackData = paymentData['data'] as Map<String, dynamic>?;

        final authorizationUrl = paystackData?['authorization_url'] as String?;

        if (authorizationUrl == null) {
          _showErrorDialog('Payment initialization failed.');

          return;
        }

        final uri = Uri.parse(authorizationUrl);

        if (!await canLaunchUrl(uri)) {
          _showErrorDialog('Could not open payment page.');

          return;
        }

        cart.clearCart();

        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          context.pop();
        }

        return;
      }

      // ───────────────── Wallet ─────────────────

      if (_paymentMethod == CheckoutPaymentMethod.wallet) {
        await auth.refreshUser();
      }

      cart.clearCart();

      HapticFeedback.heavyImpact();

      setState(() {
        _isSuccess = true;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'An error occurred during checkout.';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      } else if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }

      _showErrorDialog(message);
    } catch (_) {
      if (!mounted) return;

      _showErrorDialog('Unexpected error occurred.');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// EXTENSIONS
// ─────────────────────────────────────────────────────────────

extension NullableStringExtension on String? {
  bool isNotNullOrEmpty() {
    return this != null && this!.isNotEmpty;
  }
}
