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
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.items;

    if (items.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Browse Stores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    final currentStore = StaticData.stores.firstWhere((s) => s.id == cartProvider.currentStoreId);
    final accentColor = Color(int.parse(currentStore.accentColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => cartProvider.clearCart(),
            child: Text('Clear', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(cartProvider.editingOrderId != null ? 80 : 40),
          child: Column(
            children: [
              if (cartProvider.editingOrderId != null)
                Container(
                  width: double.infinity,
                  color: Colors.orange[50],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Editing Order',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => cartProvider.stopEditing(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    children: [
                      const TextSpan(text: 'Ordering from '),
                      TextSpan(
                        text: currentStore.name,
                        style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.map((item) => _buildCartItem(context, cartProvider, item)),
            const SizedBox(height: 20),
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', cartProvider.subTotal),
            _buildSummaryRow('Delivery Fees', cartProvider.deliveryFees),
            _buildSummaryRow('Service Charges', cartProvider.serviceFees),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '₦${cartProvider.cartTotal.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: ElevatedButton(
          onPressed: () => context.push('/checkout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            minimumSize: const Size(double.infinity, 0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Text('₦${cartProvider.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartProvider cartProvider, CartItem item) {
    final meatDesc = item.selectedMeats != null 
        ? item.selectedMeats!.entries
            .where((e) => e.value > 0)
            .map((e) => '${e.value}x ${e.key}')
            .join(', ')
        : '';

    double itemTotalPrice = item.menuItem.price;
    if (item.selectedMeats != null) {
      item.selectedMeats!.forEach((type, count) {
        itemTotalPrice += (StaticData.meatPrices[type] ?? 0) * count;
      });
    }
    if (item.hasSalad) itemTotalPrice += StaticData.saladPrice;
    if (item.selectedAddons != null) {
        item.selectedAddons!.forEach((addonId, count) {
          final addonItem = StaticData.menuItems.firstWhere((m) => m.id == addonId);
          itemTotalPrice += addonItem.price * count;
        });
      }

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
                Text(
                  item.menuItem.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meatDesc.isNotEmpty)
                  Text('🍖 $meatDesc', style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
                if (item.hasSalad)
                  Text('🥗 Includes Fresh Salad', style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
                Text(
                  '₦${itemTotalPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => cartProvider.updateQuantity(item.menuItem.id, item.quantity - 1, selectedMeats: item.selectedMeats),
                  icon: Icon(
                    item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                    size: 16,
                    color: item.quantity == 1 ? Colors.red : Colors.black,
                  ),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => cartProvider.updateQuantity(item.menuItem.id, item.quantity + 1, selectedMeats: item.selectedMeats),
                  icon: const Icon(Icons.add, size: 16),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          Text('₦${value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
