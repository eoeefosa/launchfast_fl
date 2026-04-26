import 'package:flutter/material.dart';
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
  final Map<String, int> selectedMeats;
  final bool hasSalad;
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
    required this.selectedMeats,
    required this.hasSalad,
    required this.selectedAddons,
    required this.availableSoups,
    required this.cartProvider,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderTop = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey[200]!;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: surfaceBg,
        border: Border(top: BorderSide(color: borderTop, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
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
          const SizedBox(width: 14),
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
    final bg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100]!;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? accentColor : Colors.grey.withValues(alpha: 0.35),
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
          height: 52,
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: BorderRadius.circular(14),
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
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Add to Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '₦${widget.totalPrice.toStringAsFixed(2)}',
                    key: ValueKey(widget.totalPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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
