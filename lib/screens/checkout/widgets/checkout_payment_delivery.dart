import 'package:flutter/material.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../checkout_screen.dart';

class DeliveryOptions extends StatelessWidget {
  const DeliveryOptions({
    super.key,
    required this.cart,
    required this.selected,
    required this.onChanged,
  });

  final CartProvider cart;
  final DeliveryType selected;
  final ValueChanged<DeliveryType> onChanged;

  @override
  Widget build(BuildContext context) {
    final priorityFee = cart
        .deliveryChargeFor(DeliveryType.priority)
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return Column(
      children: [
        OptionTile(
          title: 'Priority Delivery',
          subtitle: 'Fast delivery to your location',
          trailingText: '₦$priorityFee',
          icon: Icons.flash_on_rounded,
          active: selected == DeliveryType.priority,
          onTap: () => onChanged(DeliveryType.priority),
        ),
        const SizedBox(height: 10),
        OptionTile(
          title: 'Store Pickup',
          subtitle: 'Pick up your order yourself',
          trailingText: 'FREE',
          icon: Icons.storefront_rounded,
          active: selected == DeliveryType.pickup,
          onTap: () => onChanged(DeliveryType.pickup),
        ),
      ],
    );
  }
}

class PaymentOptions extends StatelessWidget {
  const PaymentOptions({
    super.key,
    required this.auth,
    required this.total,
    required this.selected,
    required this.onChanged,
    required this.onFundWallet,
  });

  final AuthProvider auth;
  final double total;
  final CheckoutPaymentMethod selected;
  final ValueChanged<CheckoutPaymentMethod> onChanged;
  final VoidCallback onFundWallet;

  @override
  Widget build(BuildContext context) {
    final balance = auth.user?.walletBalance ?? 0;
    final insufficient = !auth.hasSufficientFunds(total);
    final walletSelected = selected == CheckoutPaymentMethod.wallet;

    return Column(
      children: [
        OptionTile(
          title: 'Wallet',
          subtitle: 'Balance: ₦${balance.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          active: walletSelected,
          error: walletSelected && insufficient,
          onTap: () => onChanged(CheckoutPaymentMethod.wallet),
        ),
        const SizedBox(height: 10),
        OptionTile(
          title: 'Paystack',
          subtitle: 'Card • Transfer • USSD',
          icon: Icons.credit_card_rounded,
          active: selected == CheckoutPaymentMethod.paystack,
          onTap: () => onChanged(CheckoutPaymentMethod.paystack),
        ),
        if (walletSelected && insufficient) ...[
          const SizedBox(height: 16),
          InsufficientBanner(onFund: onFundWallet),
        ],
      ],
    );
  }
}

class InsufficientBanner extends StatelessWidget {
  const InsufficientBanner({super.key, required this.onFund});

  final VoidCallback onFund;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            TextButton(onPressed: onFund, child: const Text('Fund')),
          ],
        ),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.onTap,
    this.trailingText,
    this.error = false,
  });

  final String title;
  final String subtitle;
  final String? trailingText;
  final IconData icon;
  final bool active;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = error ? Colors.red : scheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? primary : scheme.outlineVariant,
            width: active ? 1.5 : 1,
          ),
          color: active
              ? primary.withValues(alpha: 0.06)
              : scheme.surfaceContainerLow,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: active ? primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: active
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : scheme.onSurface,
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
                      color: error
                          ? Colors.red
                          : scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight:
                          error ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: active ? primary : scheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
