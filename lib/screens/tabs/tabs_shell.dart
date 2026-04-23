import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Stats',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Users',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          activeIcon: Icon(Icons.storefront),
          label: 'Stores',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (user?.role == 'store_owner') {
      items = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu_outlined),
          activeIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (user?.role == 'rider') {
      items = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.delivery_dining_outlined),
          activeIcon: Icon(Icons.delivery_dining),
          label: 'Deliveries',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          activeIcon: Icon(Icons.history),
          label: 'History',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      items = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _buildCartIcon(totalQuantity, false, context),
          activeIcon: _buildCartIcon(totalQuantity, true, context),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    final isIOS = Platform.isIOS;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      extendBody: true, // Allows content to show behind glass bar
      body: navigationShell,
      bottomNavigationBar: isIOS
          ? _buildIOSBar(context, navigationShell, items, primaryColor)
          : _buildAndroidBar(context, navigationShell, items, primaryColor),
    );
  }

  Widget _buildIOSBar(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    List<BottomNavigationBarItem> items,
    Color primaryColor,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
          ),
          child: CupertinoTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) {
              HapticFeedback.lightImpact();
              navigationShell.goBranch(index);
            },
            backgroundColor: Colors.transparent,
            activeColor: primaryColor,
            inactiveColor: Colors.grey[400]!,
            items: items.map((item) {
              final isActive =
                  items.indexOf(item) == navigationShell.currentIndex;
              return BottomNavigationBarItem(
                icon: _AnimatedIcon(
                  icon: item.icon,
                  isActive: isActive,
                  activeColor: primaryColor,
                ),
                label: item.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidBar(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    List<BottomNavigationBarItem> items,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: primaryColor.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              );
            }
            return const TextStyle(fontSize: 12, color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            navigationShell.goBranch(index);
          },
          backgroundColor: Colors.white,
          elevation: 0,
          height: 70,
          destinations: items.map((item) {
            final isActive =
                items.indexOf(item) == navigationShell.currentIndex;
            return NavigationDestination(
              icon: _AnimatedIcon(
                icon: item.icon,
                isActive: isActive,
                activeColor: primaryColor,
              ),
              selectedIcon: _AnimatedIcon(
                icon: item.activeIcon,
                isActive: isActive,
                activeColor: primaryColor,
              ),
              label: item.label!,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AnimatedIcon extends StatelessWidget {
  final Widget icon;
  final bool isActive;
  final Color activeColor;

  const _AnimatedIcon({
    required this.icon,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return icon;

    return icon
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        )
        .tint(color: activeColor);
  }
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  );
}
