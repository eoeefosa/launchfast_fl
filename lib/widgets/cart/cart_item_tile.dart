import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../constants/static_data.dart';
import '../../constants/app_colors.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  double _calculatePrice() {
    double total = item.menuItem.price;

    item.selectedMeats?.forEach((type, count) {
      total += (StaticData.meatPrices[type] ?? 0) * count;
    });

    if (item.hasSalad) total += StaticData.saladPrice;

    item.selectedAddons?.forEach((id, count) {
      final addon = StaticData.menuItems.firstWhere((m) => m.id == id);
      total += addon.price * count;
    });

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
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
                child: CachedNetworkImage(
                  imageUrl: item.menuItem.image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
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
                        '₦${_calculatePrice().toStringAsFixed(2)}',
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
