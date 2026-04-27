import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class TabsShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TabsShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final totalQuantity = cartProvider.totalQuantity;

    final List<BottomNavigationBarItem> items = [
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

    final isIOS = Platform.isIOS;
    // final primaryColor = Theme.of(context).primaryColor;
    // final scheme = Theme.of(context).colorScheme;
    final activeColor = Colors.orangeAccent; // More vibrant orange for dark mode

    return Scaffold(
      extendBody: true, // Allows content to show behind glass bar
      body: navigationShell,
      bottomNavigationBar: isIOS
          ? _buildIOSBar(context, navigationShell, items, activeColor)
          : _buildAndroidBar(context, navigationShell, items, activeColor),
    );
  }

  Widget _buildIOSBar(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    List<BottomNavigationBarItem> items,
    Color activeColor,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: scheme.onSurface.withValues(alpha: 0.1),
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
            activeColor: activeColor,
            inactiveColor: scheme.onSurface.withValues(alpha: 0.45),
            items: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = index == navigationShell.currentIndex;
              return BottomNavigationBarItem(
                icon: _AnimatedIcon(
                  icon: item.icon,
                  isActive: isActive,
                  activeColor: activeColor,
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
    Color activeColor,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: activeColor.withValues(alpha: 0.15),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: activeColor, size: 28);
            }
            return IconThemeData(
              color: scheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: activeColor,
                letterSpacing: 0.2,
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.5),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            navigationShell.goBranch(index);
          },
          backgroundColor: scheme.surface,
          elevation: 0,
          height: 80,
          destinations: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = index == navigationShell.currentIndex;
            return NavigationDestination(
              icon: _AnimatedIcon(
                icon: item.icon,
                isActive: isActive,
                activeColor: activeColor,
              ),
              selectedIcon: _AnimatedIcon(
                icon: item.activeIcon,
                isActive: isActive,
                activeColor: activeColor,
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
          end: const Offset(1.12, 1.12),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }
}

Widget _buildCartIcon(int quantity, bool isActive, BuildContext context) {
  final activeColor = Colors.orangeAccent;
  final scheme = Theme.of(context).colorScheme;

  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(
        isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined,
        color: isActive ? activeColor : scheme.onSurface.withValues(alpha: 0.6),
      ),
      if (quantity > 0)
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.surface, width: 1.5),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
    ],
  );
}
