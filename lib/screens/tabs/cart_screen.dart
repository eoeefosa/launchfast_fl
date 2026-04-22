import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/cart_provider.dart';
import '../../constants/static_data.dart';
import '../../models/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty) return const _EmptyCartView();

    final store = StaticData.stores.firstWhere(
      (s) => s.id == cart.currentStoreId,
    );

    final accentColor = Color(
      int.parse(store.accentColor.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          TextButton(onPressed: cart.clearCart, child: const Text('Clear')),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            cart.editingOrderId != null ? 140 : 100,
          ),
          child: Column(
            children: [
              if (cart.editingOrderId != null) const _EditingBanner(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      const TextSpan(text: 'Ordering from '),
                      TextSpan(
                        text: store.name,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
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
      body: _CartBody(cart: cart),
      bottomSheet: _CheckoutBar(total: cart.cartTotal),
    );
  }
}

// ================= EMPTY VIEW =================
class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Looks like you haven't added anything yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Browse Stores'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditingBanner extends StatelessWidget {
  const _EditingBanner();

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Container(
      width: double.infinity,
      color: Colors.orange[50],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(child: Text('Editing Order')),
          TextButton(onPressed: cart.stopEditing, child: const Text('Cancel')),
        ],
      ),
    );
  }
}

// ================= BODY =================
class _CartBody extends StatelessWidget {
  final CartProvider cart;

  const _CartBody({required this.cart});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ...cart.items.map((item) => CartItemTile(item: item)),
          const SizedBox(height: 20),
          const _SummarySection(),
        ],
      ),
    );
  }
}

// ================= ITEM TILE =================
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.menuItem.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuItem.name),
                Text('₦${_calculatePrice().toStringAsFixed(2)}'),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    cart.updateQuantity(item.menuItem.id, item.quantity - 1),
                icon: const Icon(Icons.remove),
              ),
              Text('${item.quantity}'),
              IconButton(
                onPressed: () =>
                    cart.updateQuantity(item.menuItem.id, item.quantity + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= SUMMARY =================
class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary'),
        const SizedBox(height: 10),
        _row('Subtotal', cart.subTotal),
        _row('Delivery', cart.deliveryFees),
        _row('Service', cart.serviceFees),
        const Divider(),
        _row('Total', cart.cartTotal, isBold: true),
      ],
    );
  }

  Widget _row(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '₦${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ================= CHECKOUT =================
class _CheckoutBar extends StatelessWidget {
  final double total;

  const _CheckoutBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () => context.push('/checkout'),
        child: Text('Checkout • ₦${total.toStringAsFixed(2)}'),
      ),
    );
  }
}
