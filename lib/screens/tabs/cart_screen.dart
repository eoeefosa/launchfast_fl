import 'dart:io';
import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/cart/cart_item_tile.dart';
import '../../widgets/cart/checkout_bar.dart';
import '../../widgets/cart/editing_banner.dart';
import '../../widgets/cart/empty_cart_view.dart';
import '../../widgets/cart/frequently_added_section.dart';
import '../../widgets/cart/order_summary.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final isIOS = Platform.isIOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;
    final accentColor = _getAccentColor(context, cart);

    final hasUnavailableItems = cart.items.any((item) {
      final menuItem = storeProvider.menuItems.firstWhere(
        (m) => m.id == item.menuItem.id,
        orElse: () => item.menuItem,
      );
      return !menuItem.isReady;
    });

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: cart.items.isEmpty
          ? const EmptyCartView(key: ValueKey('empty_cart'))
          : Scaffold(
              key: const ValueKey('cart_scaffold'),
              backgroundColor: scaffoldBg,
              appBar: _buildAppBar(context, isIOS, cart),
              body: _CartBody(cart: cart, accentColor: accentColor),
              bottomNavigationBar: CheckoutBar(
                total: cart.cartTotal,
                enabled: !hasUnavailableItems,
                onPressed: () {
                  final hasSwallowWithoutSoup = cart.items.any(
                    (item) =>
                        (item.menuItem.type == 'swallow' ||
                            item.menuItem.category == 'Swallow' ||
                            item.menuItem.requiresSoupSelection) &&
                        (item.selectedSoup == null ||
                            item.selectedSoup!['id'] == null),
                  );

                  if (hasSwallowWithoutSoup) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A soup selection is required for your swallow items before checking out.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                    return;
                  }

                  context.push('/checkout');
                },
              ),
            ),
    );
  }

  Color _getAccentColor(BuildContext context, CartProvider cart) {
    if (cart.items.isEmpty) return AppColors.primary;
    final stores = context.read<StoreProvider>().stores;
    final store = stores.firstWhere(
      (s) => s.id == cart.currentStoreId,
      orElse: () => stores.first,
    );
    return store.accentColor;
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isIOS,
    CartProvider cart,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    if (isIOS) {
      return CupertinoNavigationBar(
        middle: Text(
          'Your Cart',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
            fontSize: 16.sp, // slightly smaller
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: cart.clearCart,
          child: const Text(
            'Clear',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
        backgroundColor: surfaceColor.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.4)
                : AppColors.lightBorder.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      );
    }

    return AppBar(
      title: Text(
        'Your Cart',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20.sp, // 22 → 20
          color: textColor,
        ),
      ),
      centerTitle: false,
      actions: [
        TextButton(
          onPressed: cart.clearCart,
          child: Text(
            'Clear All',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.sp, // 14 → 13
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightMuted,
            ),
          ),
        ),
      ],
      backgroundColor: surfaceColor,
      surfaceTintColor: surfaceColor,
      elevation: 0,
    );
  }
}

class _CartBody extends StatelessWidget {
  final CartProvider cart;
  final Color accentColor;

  const _CartBody({required this.cart, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final cardBorder = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : AppColors.lightBorder.withValues(alpha: 0.4);
    final storeBg = accentColor.withValues(alpha: isDark ? 0.15 : 0.1);

    final stores = context.read<StoreProvider>().stores;
    final store = stores.firstWhere(
      (s) => s.id == cart.currentStoreId,
      orElse: () => stores.first,
    );
    final storeName = store.name;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20.w,
        10.h,
        20.w,
        90.h,
      ), // top 12 → 10, bottom 100 → 90
      children: [
        if (cart.editingOrderId != null)
          Padding(
            padding: EdgeInsets.only(bottom: 14.h), // 16 → 14
            child: const EditingBanner(),
          ),

        // Store Header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ), // 14 → 12, 10 → 8
          decoration: BoxDecoration(
            color: storeBg,
            borderRadius: BorderRadius.circular(12.r), // 14 → 12
          ),
          child: Row(
            children: [
              Icon(
                Icons.store_rounded,
                color: accentColor,
                size: 16.sp,
              ), // 18 → 16
              SizedBox(width: 8.w), // 10 → 8
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12.sp,
                    ), // 13 → 12
                    children: [
                      const TextSpan(text: 'Ordering from '),
                      TextSpan(
                        text: storeName,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 5.w,
                  vertical: 2.h,
                ), // 6 → 5, 3 → 2
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(5.r), // 6 → 5
                ),
                child: Text(
                  store.deliveryTime,
                  style: TextStyle(
                    fontSize: 9.sp, // 10 → 9
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: -0.1),

        SizedBox(height: 16.h), // 20 → 16
        // Cart Items
        ...cart.items.map(
          (item) => CartItemTile(key: ValueKey(item.id), item: item),
        ),

        SizedBox(height: 16.h), // 20 → 16
        // Frequently Added Carousel
        if (cart.currentStoreId != null)
          FrequentlyAddedSection(
            storeId: cart.currentStoreId!,
            accentColor: accentColor,
          ),

        SizedBox(height: 16.h), // 20 → 16
        // Order Summary
        const OrderSummary(),

        SizedBox(height: 28.h), // 32 → 28
        // Promo code section
        GestureDetector(
          onTap: () => _showPromoCodeSheet(context, cart),
          child: Container(
            padding: EdgeInsets.all(14.r), // 16 → 14
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(18.r), // 20 → 18
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: cart.appliedPromoCode != null
                      ? Colors.green
                      : mutedColor.withValues(alpha: 0.6),
                  size: 16.sp, // 18 → 16
                ),
                SizedBox(width: 8.w), // 10 → 8
                Text(
                  cart.appliedPromoCode != null
                      ? 'Promo applied: ${cart.appliedPromoCode}'
                      : 'Add promo code',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp, // 13 → 12
                    color: cart.appliedPromoCode != null
                        ? Colors.green
                        : mutedColor,
                  ),
                ),
                const Spacer(),
                if (cart.appliedPromoCode != null)
                  GestureDetector(
                    onTap: () => cart.removePromoCode(),
                    child: Icon(
                      Icons.close,
                      size: 16.sp,
                      color: Colors.red,
                    ), // 18 → 16
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11.sp, // 12 → 11
                    color: mutedColor.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ),
      ],
    );
  }

  void _showPromoCodeSheet(BuildContext context, CartProvider cart) {
    if (cart.appliedPromoCode != null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PromoCodeSheet(cart: cart),
    );
  }
}

class _PromoCodeSheet extends StatefulWidget {
  final CartProvider cart;

  const _PromoCodeSheet({required this.cart});

  @override
  State<_PromoCodeSheet> createState() => _PromoCodeSheetState();
}

class _PromoCodeSheetState extends State<_PromoCodeSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await apiService.dio.post(
        '/promo-codes/validate',
        data: {'code': code, 'cartAmount': widget.cart.subTotal},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        widget.cart.applyPromoCode(
          response.data['code'],
          (response.data['discountPercentage'] as num).toDouble(),
          (response.data['maxDiscountAmount'] as num).toDouble(),
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promo code applied successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.data['error'] ?? 'Invalid promo code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to validate promo code';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(18.r), // 20 → 18
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Promo Code',
                style: TextStyle(
                  fontSize: 17.sp, // 18 → 17
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              SizedBox(height: 10.h), // 12 → 10
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: textColor, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'e.g. DISCOUNT20',
                  hintStyle: TextStyle(color: mutedColor, fontSize: 12.sp),
                  errorText: _errorMessage,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface2.withValues(alpha: 0.5)
                      : AppColors.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 16.h), // 20 → 16
              SizedBox(
                width: double.infinity,
                height: 44.h, // 46 → 44
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _applyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    textStyle: TextStyle(
                      fontSize: 14.sp, // 15 → 14
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 16.r, // 18 → 16
                          width: 16.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Apply Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
