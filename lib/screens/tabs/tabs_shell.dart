import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class TabsShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TabsShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();
    final totalQuantity = cartProvider.totalQuantity;
    final user = authProvider.user;

    List<BottomNavigationBarItem> items = [];

    if (user?.role == 'admin') {
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Stats'),
        const BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
        const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Stores'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (user?.role == 'store_owner') {
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
        const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (user?.role == 'rider') {
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_outlined), activeIcon: Icon(Icons.delivery_dining), label: 'Deliveries'),
        const BottomNavigationBarItem(icon: Icon(Icons.history_rounded), activeIcon: Icon(Icons.history), label: 'History'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: _buildCartIcon(totalQuantity, false, context),
          activeIcon: _buildCartIcon(totalQuantity, true, context),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: items,
      ),
    );
  }

  Widget _buildCartIcon(int quantity, bool isActive, BuildContext context) {
    return Stack(
      children: [
        Icon(isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined),
        if (quantity > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$quantity',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
