import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../widgets/common/liquid_glass_bottom_bar.dart';
import '../../widgets/responsive_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell
// ─────────────────────────────────────────────────────────────────────────────

class TabsShell extends StatelessWidget {
  const TabsShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // ── Nav-item definitions ───────────────────────────────────────────────────

  /// iOS items — use [LiquidGlassNavItem] so badge and icons are handled
  /// by [LiquidGlassBottomBar] directly.
  List<LiquidGlassNavItem> _iosItems(int cartQty) => [
    const LiquidGlassNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    LiquidGlassNavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart,
      label: 'Cart',
      badgeCount: cartQty,
    ),
    const LiquidGlassNavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Orders',
    ),
    const LiquidGlassNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cartQty = context.watch<CartProvider>().totalQuantity;
    final scheme = Theme.of(context).colorScheme;

    return ResponsiveLayout(
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: Platform.isIOS
            ? _IosBar(
                navigationShell: navigationShell,
                items: _iosItems(cartQty),
              )
            : _AndroidBar(
                navigationShell: navigationShell,
                cartQty: cartQty,
                activeColor: scheme.primary,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS — Liquid Glass bar
// ─────────────────────────────────────────────────────────────────────────────

class _IosBar extends StatelessWidget {
  const _IosBar({required this.navigationShell, required this.items});

  final StatefulNavigationShell navigationShell;
  final List<LiquidGlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBottomBar(
      currentIndex: navigationShell.currentIndex,
      onTap: navigationShell.goBranch,
      items: items,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Android — Material 3 NavigationBar
// ─────────────────────────────────────────────────────────────────────────────

class _AndroidBar extends StatelessWidget {
  const _AndroidBar({
    required this.navigationShell,
    required this.cartQty,
    required this.activeColor,
  });

  final StatefulNavigationShell navigationShell;
  final int cartQty;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : scheme.onSurface.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: activeColor.withValues(alpha: 0.14),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: activeColor, size: 26);
            }
            return IconThemeData(
              color: scheme.onSurface.withValues(alpha: 0.55),
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: activeColor,
                letterSpacing: 0.2,
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.50),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            navigationShell.goBranch(index);
          },
          backgroundColor: scheme.surface,
          elevation: 0,
          height: 80,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: _PulsingIcon(icon: Icon(Icons.home)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: _CartIcon(quantity: cartQty, isActive: false),
              selectedIcon: _CartIcon(quantity: cartQty, isActive: true),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: _PulsingIcon(icon: Icon(Icons.receipt_long)),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: _PulsingIcon(icon: Icon(Icons.person)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Subtle breathing animation for the active icon on Android.
class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return icon
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.10, 1.10),
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Cart icon with a badge overlay, used in the Android [NavigationBar].
class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.quantity, required this.isActive});

  final int quantity;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isActive
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.55);

    Widget iconWidget = Icon(
      isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined,
      color: color,
    );

    if (isActive) {
      iconWidget = _PulsingIcon(icon: iconWidget);
    }

    if (quantity <= 0) return iconWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.surface, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: scheme.error.withValues(alpha: 0.40),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Center(
              child: Text(
                quantity > 99 ? '99+' : '$quantity',
                style: TextStyle(
                  color: scheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
