import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:campuschow/providers/store_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/cart_provider.dart';
import '../../widgets/cart/cart_item_tile.dart';
import '../../widgets/cart/order_summary.dart';
import '../../widgets/cart/checkout_bar.dart';
import '../../widgets/cart/empty_cart_view.dart';
import '../../widgets/cart/editing_banner.dart';
import '../../widgets/cart/frequently_added_section.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final isIOS = Platform.isIOS;

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
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: _buildAppBar(context, isIOS, cart),
              body: _CartBody(
                cart: cart,
                accentColor: _getAccentColor(context, cart),
              ),
              bottomNavigationBar: CheckoutBar(
                total: cart.cartTotal,
                enabled: !hasUnavailableItems,
              ),
            ),
    );
  }

  Color _getAccentColor(BuildContext context, CartProvider cart) {
    if (cart.items.isEmpty) return Colors.orange;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isIOS) {
      return CupertinoNavigationBar(
        middle: Text(
          'Your Cart',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
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
        backgroundColor: scheme.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      );
    }

    return AppBar(
      title: const Text(
        'Your Cart',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
      ),
      centerTitle: false,
      actions: [
        TextButton(
          onPressed: cart.clearCart,
          child: const Text(
            'Clear All',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surface,
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
    final scheme = Theme.of(context).colorScheme;
    final stores = context.read<StoreProvider>().stores;
    final store = stores.firstWhere(
      (s) => s.id == cart.currentStoreId,
      orElse: () => stores.first,
    );
    final storeName = store.name;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        if (cart.editingOrderId != null)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: EditingBanner(),
          ),

        // Store Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.store_rounded, color: accentColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: scheme.onSurface, fontSize: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  store.deliveryTime,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: -0.1),

        const SizedBox(height: 24),

        // Cart Items
        ...cart.items.map(
          (item) => CartItemTile(key: ValueKey(item.id), item: item),
        ),

        const SizedBox(height: 24),

        // Frequently Added Carousel
        FrequentlyAddedSection(
          storeId: cart.currentStoreId!,
          accentColor: accentColor,
        ),

        const SizedBox(height: 24),

        // Summary
        const OrderSummary(),

        const SizedBox(height: 40),

        // Notes or Promo Code Placeholder
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              Text(
                'Add promo code',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: scheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}
