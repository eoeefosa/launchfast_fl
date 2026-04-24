import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/cart_provider.dart';
import '../../constants/static_data.dart';
import '../../widgets/cart/cart_item_tile.dart';
import '../../widgets/cart/order_summary.dart';
import '../../widgets/cart/checkout_bar.dart';
import '../../widgets/cart/empty_cart_view.dart';
import '../../widgets/cart/editing_banner.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isIOS = Platform.isIOS;

    if (cart.items.isEmpty) return const EmptyCartView();

    final store = StaticData.stores.firstWhere(
      (s) => s.id == cart.currentStoreId,
    );

    final accentColor = Color(
      int.parse(store.accentColor.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, isIOS, store, accentColor, cart),
      body: _CartBody(
        cart: cart,
        storeName: store.name,
        accentColor: accentColor,
      ),
      bottomNavigationBar: CheckoutBar(total: cart.cartTotal),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isIOS,
    dynamic store,
    Color accentColor,
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
  final String storeName;
  final Color accentColor;

  const _CartBody({
    required this.cart,
    required this.storeName,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                  ),
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
            ],
          ),
        ).animate().fadeIn().slideX(begin: -0.1),

        const SizedBox(height: 24),

        // Cart Items
        ...cart.items.map((item) => CartItemTile(item: item)),

        const SizedBox(height: 12),

        // Summary
        const OrderSummary(),

        const SizedBox(height: 40),

        // Notes or Promo Code Placeholder
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.1),
            ),
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
