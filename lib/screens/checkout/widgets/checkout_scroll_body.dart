import 'package:flutter/material.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../checkout_screen.dart';
import 'checkout_app_bar.dart';
import 'checkout_guest_widgets.dart';
import 'checkout_payment_delivery.dart';
import 'checkout_section.dart';
import 'order_summary_section.dart';

/// Renders the scrollable sections of the checkout screen.
class CheckoutScrollBody extends StatelessWidget {
  const CheckoutScrollBody({
    super.key,
    required this.auth,
    required this.cart,
    required this.deliveryType,
    required this.paymentMethod,
    required this.isGuestCheckout,
    required this.guestNameController,
    required this.guestPhoneController,
    required this.total,
    required this.onDeliveryTypeChanged,
    required this.onPaymentMethodChanged,
    required this.onGuestContinue,
    required this.onShowError,
    required this.onFundWallet,
  });

  final AuthProvider auth;
  final CartProvider cart;
  final DeliveryType deliveryType;
  final CheckoutPaymentMethod paymentMethod;
  final bool isGuestCheckout;
  final TextEditingController guestNameController;
  final TextEditingController guestPhoneController;
  final double total;
  final ValueChanged<DeliveryType> onDeliveryTypeChanged;
  final ValueChanged<CheckoutPaymentMethod> onPaymentMethodChanged;
  final VoidCallback onGuestContinue;
  final ValueChanged<String> onShowError;
  final VoidCallback onFundWallet;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App bar
        const SliverToBoxAdapter(child: CheckoutAppBar()),

        // Delivery address
        SliverToBoxAdapter(
          child: CheckoutSection(
            title: 'DELIVERY ADDRESS',
            child: GuestAddressTile(auth: auth),
          ),
        ),

        // Guest contact form (shown only when needed)
        if (isGuestCheckout)
          SliverToBoxAdapter(
            child: CheckoutSection(
              title: 'CONTACT DETAILS',
              child: GuestContactForm(
                nameController: guestNameController,
                phoneController: guestPhoneController,
                onContinue: onGuestContinue,
                onError: onShowError,
              ),
            ),
          ),

        // Delivery option
        SliverToBoxAdapter(
          child: CheckoutSection(
            title: 'DELIVERY OPTION',
            child: DeliveryOptions(
              cart: cart,
              selected: deliveryType,
              onChanged: onDeliveryTypeChanged,
            ),
          ),
        ),

        // Payment method
        SliverToBoxAdapter(
          child: CheckoutSection(
            title: 'PAYMENT METHOD',
            child: PaymentOptions(
              auth: auth,
              total: total,
              selected: paymentMethod,
              onChanged: onPaymentMethodChanged,
              onFundWallet: onFundWallet,
            ),
          ),
        ),

        // Order summary
        SliverToBoxAdapter(
          child: CheckoutSection(
            title: 'ORDER SUMMARY',
            child: OrderSummarySection(
              cart: cart,
              deliveryType: deliveryType,
            ),
          ),
        ),

        // Bottom padding so content clears the sticky BottomBar.
        const SliverToBoxAdapter(child: SizedBox(height: 150)),
      ],
    );
  }
}
