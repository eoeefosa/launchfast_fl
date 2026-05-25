import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/menu_item.dart';
import '../../../providers/cart_provider.dart';

// ─────────────────────────────────────────────
//  Bottom footer — quantity stepper + add-to-cart
// ─────────────────────────────────────────────

class ItemDetailFooter extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final double totalPrice;
  final Color accentColor;
  final bool isDark;
  final String? selectedSoupId;
  final String? selectedSizeId; // NEW – unused but accepted
  final Map<String, int> selectedMeats;
  final Map<String, int> selectedSides;
  final Map<String, int> selectedDrinks;
  final Map<String, int> selectedAddons;
  final List<MenuItem> availableSoups;
  final CartProvider cartProvider;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  const ItemDetailFooter({
    super.key,
    required this.item,
    required this.quantity,
    required this.totalPrice,
    required this.accentColor,
    required this.isDark,
    required this.selectedSoupId,
    this.selectedSizeId, // optional, defaults to null
    required this.selectedMeats,
    required this.selectedSides,
    required this.selectedDrinks,
    required this.selectedAddons,
    required this.availableSoups,
    required this.cartProvider,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    // ── AppColors surfaces ──────────────────────────────────────────
    final surfaceBg = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final borderTop = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.4)
        : AppColors.lightBorder.withValues(alpha: 0.6);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: surfaceBg,
        border: Border(top: BorderSide(color: borderTop, width: 1)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          ItemDetailQuantityStepper(
            quantity: quantity,
            accentColor: accentColor,
            isDark: isDark,
            onDecrement: () {
              if (quantity > 1) onQuantityChanged(quantity - 1);
            },
            onIncrement: () => onQuantityChanged(quantity + 1),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: ItemDetailAddToCartButton(
              totalPrice: totalPrice,
              accentColor: accentColor,
              onTap: onAddToCart,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quantity stepper (footer version)
// ─────────────────────────────────────────────

class ItemDetailQuantityStepper extends StatelessWidget {
  final int quantity;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const ItemDetailQuantityStepper({
    super.key,
    required this.quantity,
    required this.accentColor,
    required this.isDark,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurface2.withValues(alpha: 0.5)
        : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ItemDetailFooterStepButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            enabled: quantity > 1,
            accentColor: accentColor,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
          ),
          ItemDetailFooterStepButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            enabled: true,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class ItemDetailFooterStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color accentColor;

  const ItemDetailFooterStepButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = Colors.grey.withValues(alpha: 0.35);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Icon(
            icon,
            size: 20.sp,
            color: enabled ? accentColor : disabledColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Add-to-cart button with press animation
// ─────────────────────────────────────────────

class ItemDetailAddToCartButton extends StatefulWidget {
  final double totalPrice;
  final Color accentColor;
  final VoidCallback onTap;

  const ItemDetailAddToCartButton({
    super.key,
    required this.totalPrice,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<ItemDetailAddToCartButton> createState() =>
      _ItemDetailAddToCartButtonState();
}

class _ItemDetailAddToCartButtonState extends State<ItemDetailAddToCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _pressController.forward();
  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 52.h,
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.w),
                child: Text(
                  'Add to Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 6.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '₦${widget.totalPrice.toStringAsFixed(2)}',
                    key: ValueKey(widget.totalPrice),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
