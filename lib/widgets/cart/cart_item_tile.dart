import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../common/universal_image.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../constants/app_colors.dart';
import '../../utils/price_calculator.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final storeProvider = context.read<StoreProvider>();
    final isIOS = Platform.isIOS;
    final customizationSummary = PriceCalculator.getCustomizationSummary(
      item,
      allMenuItems: storeProvider.menuItems,
    );
    final itemTotal = PriceCalculator.calculateCartItemPrice(
      item,
      meatPrices: storeProvider.meatPrices,
      saladPrice: storeProvider.saladPrice,
      allMenuItems: storeProvider.menuItems,
    );

    // Find current readiness from provider as model might be stale
    final isReady = storeProvider.menuItems
        .firstWhere((m) => m.id == item.menuItem.id, orElse: () => item.menuItem)
        .isReady;

    return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: !isReady ? Border.all(color: Colors.red.withValues(alpha: 0.5), width: 2) : null,
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
                  Stack(
                    children: [
                      Hero(
                        tag: 'cart_item_${item.id}',
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
                      if (!isReady)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            child: const Center(
                              child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Details Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                          if (!isReady)
                            const Text(
                              'Item no longer available',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else if (customizationSummary.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              customizationSummary,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '₦${itemTotal.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              if (isReady) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    // In a real app, we'd pass the item to edit.
                                    // For now, we just navigate to the detail page.
                                    context.push('/item/${item.menuItem.id}');
                                  },
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _QuantityButton(
                            icon: isIOS ? CupertinoIcons.minus : Icons.remove,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              cart.updateQuantity(
                                item.menuItem.id,
                                item.quantity - 1,
                              );
                            },
                          ),
                          Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                              .animate(target: item.quantity.toDouble())
                              .scale(
                                duration: 200.ms,
                                curve: Curves.easeOutBack,
                              ),
                          _QuantityButton(
                            icon: isIOS ? CupertinoIcons.plus : Icons.add,
                            onPressed: isReady ? () {
                              HapticFeedback.lightImpact();
                              cart.updateQuantity(
                                item.menuItem.id,
                                item.quantity + 1,
                              );
                            } : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.2, curve: Curves.easeOutCubic);
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
