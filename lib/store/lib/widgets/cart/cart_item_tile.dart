import 'package:campuschow/widgets/common/universal_image.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/cart_item.dart';
import 'package:campuschow/store/lib/features/orders/presentation/cart_provider.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  double _calculatePrice(StoreProvider storeProvider) {
    double total = item.menuItem.price;

    item.selectedMeats?.forEach((id, count) {
      final meatItem = storeProvider.menuItems.where((m) => m.id == id).firstOrNull;
      if (meatItem != null) {
        total += meatItem.price * count;
      } else {
        total += (storeProvider.meatPrices[id] ?? 0) * count;
      }
    });

    item.selectedSides?.forEach((id, count) {
      final sideItem = storeProvider.menuItems.where((m) => m.id == id).firstOrNull;
      if (sideItem != null) {
        total += sideItem.price * count;
      } else {
        total += storeProvider.saladPrice * count;
      }
    });

    item.selectedDrinks?.forEach((id, count) {
      final drinkItem = storeProvider.menuItems.where((m) => m.id == id).firstOrNull;
      if (drinkItem != null) {
        total += drinkItem.price * count;
      }
    });

    item.selectedAddons?.forEach((id, count) {
      try {
        final addon = storeProvider.menuItems.firstWhere((m) => m.id == id);
        total += addon.price * count;
      } catch (_) {}
    });

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final isIOS = Platform.isIOS;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Image Section
              Hero(
                tag: 'cart_item_${item.menuItem.id}',
                child: UniversalImage(
                  imageUrl: item.menuItem.image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: AppColors.lightSurface,
                    child: const Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Details Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.menuItem.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₦${_calculatePrice(storeProvider).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quantity Controller
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QuantityButton(
                        icon: isIOS ? CupertinoIcons.minus : Icons.remove,
                        onPressed: () => cart.updateQuantity(
                          item.menuItem.id, 
                          item.quantity - 1
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ).animate(target: item.quantity.toDouble()).scale(
                        duration: 200.ms,
                        curve: Curves.easeOutBack,
                      ),
                      _QuantityButton(
                        icon: isIOS ? CupertinoIcons.plus : Icons.add,
                        onPressed: () => cart.updateQuantity(
                          item.menuItem.id, 
                          item.quantity + 1
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, curve: Curves.easeOutCubic);
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }
}
