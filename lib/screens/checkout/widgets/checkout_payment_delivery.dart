import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

    return Row(
      children: [
        Expanded(
          child: OptionTile(
            title: 'Priority',
            subtitle: '₦$priorityFee',
            icon: Icons.flash_on_rounded,
            active: selected == DeliveryType.priority,
            onTap: () => onChanged(DeliveryType.priority),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: OptionTile(
            title: 'Pickup',
            subtitle: 'FREE',
            icon: Icons.storefront_rounded,
            active: selected == DeliveryType.pickup,
            onTap: () => onChanged(DeliveryType.pickup),
          ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: OptionTile(
                title: 'Wallet',
                subtitle: '₦${balance.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_rounded,
                active: walletSelected,
                error: walletSelected && insufficient,
                onTap: () => onChanged(CheckoutPaymentMethod.wallet),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: OptionTile(
                title: 'Paystack',
                subtitle: 'Card • Transfer',
                icon: Icons.credit_card_rounded,
                active: selected == CheckoutPaymentMethod.paystack,
                onTap: () => onChanged(CheckoutPaymentMethod.paystack),
              ),
            ),
          ],
        ),
        if (walletSelected && insufficient) ...[
          SizedBox(height: 12.h),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark
        ? Colors.red.shade700.withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.08);
    final borderColor = isDark
        ? Colors.red.shade700.withValues(alpha: 0.25)
        : Colors.red.withValues(alpha: 0.2);
    final textColor = isDark ? Colors.red.shade200 : Colors.red.shade700;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: textColor, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Insufficient wallet balance.',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: onFund,
              child: Text(
                'Fund',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = error
        ? Colors.red
        : (isDark ? AppColors.darkPrimary : AppColors.primary);
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final surfaceContainerLow = isDark
        ? AppColors.darkSurface2
        : AppColors.lightSurface;
    final onSurfaceColor = isDark ? AppColors.darkText : AppColors.lightText;
    final outlineVariant = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.4)
        : AppColors.lightBorder.withValues(alpha: 0.6);
    final subtitleColor = error
        ? Colors.red
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightMuted)
              .withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        // 👇 tighter padding
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r), // slightly smaller
          border: Border.all(
            color: active ? primary : outlineVariant,
            width: active ? 1.8 : 1,
          ),
          color: active
              ? primary.withValues(alpha: isDark ? 0.12 : 0.06)
              : surfaceContainerLow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              // 👇 smaller icon box
              height: 24.h,
              width: 24.w,
              decoration: BoxDecoration(
                color: active
                    ? primary
                    : (isDark ? surfaceColor : Colors.white),
                borderRadius: BorderRadius.circular(10.r),
                border: active
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.2)
                            : Colors.grey.shade200,
                      ),
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : onSurfaceColor,
                size: 14.sp, // smaller icon
              ),
            ),
            SizedBox(height: 6.h), // less vertical space
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.sp, // slightly smaller
                color: onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 10.sp, // legible but compact
                fontWeight: error ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (trailingText != null) ...[
              SizedBox(height: 4.h),
              Text(
                trailingText!,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.sp,
                  color: active ? primary : onSurfaceColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
