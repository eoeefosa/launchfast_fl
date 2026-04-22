import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launchfast_fl/constants/app_colors.dart';
import 'package:launchfast_fl/providers/auth_provider.dart';
import 'package:launchfast_fl/services/ably_service.dart';
import 'package:launchfast_fl/models/order.dart';
import 'package:launchfast_fl/screens/dashboards/store/main_dashboard.dart';
import 'package:launchfast_fl/screens/dashboards/store/order_screen.dart';
import 'package:launchfast_fl/screens/dashboards/store/menu_screen.dart';
import 'package:launchfast_fl/screens/dashboards/store/store_setting.dart';

class StoreMainNav extends StatefulWidget {
  const StoreMainNav({super.key});

  @override
  State<StoreMainNav> createState() => _StoreMainNavState();
}

class _StoreMainNavState extends State<StoreMainNav>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // ─── Real-time notification state ─────────────────────────────────
  int _newOrderCount = 0;
  bool _ablyInitialized = false;
  late AnimationController _badgeCtrl;
  late Animation<double> _badgeScale;

  static const List<({String label, IconData icon, IconData activeIcon})>
      _navItems = [
    (
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded
    ),
    (
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded
    ),
    (
      label: 'Menu',
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu_rounded
    ),
    (
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded
    ),
  ];

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _badgeScale = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initAbly());
  }

  Future<void> _initAbly() async {
    if (_ablyInitialized) return;
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;

    try {
      await ablyService.initAbly(userId);

      // Listen for new orders via the order-update listener
      ablyService.addOrderListener((orderId, status) {
        // When a new PENDING order arrives, bump the badge on Orders tab
        if (status == OrderStatus.pending && mounted) {
          setState(() => _newOrderCount++);
          _badgeCtrl.repeat(reverse: true);
        }
      });

      // Find owned store and subscribe to its specific orders channel
      if (storeProvider.stores.isEmpty) await storeProvider.refreshData();
      final owned = storeProvider.stores.firstWhere(
        (s) => s.ownerId == userId,
        orElse: () => storeProvider.stores.first,
      );
      ablyService.subscribeToStoreOrders(owned.id);

      _ablyInitialized = true;
    } catch (_) {}
  }

  void _onTabTapped(int index) {
    // Clear badge when navigating to Orders tab
    if (index == 1 && _newOrderCount > 0) {
      setState(() => _newOrderCount = 0);
    }
    setState(() => _currentIndex = index);
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final navBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Pages (kept const where possible for performance)
    final pages = [
      StoreDashboardHome(),
      StoreOrdersScreen(),
      StoreMenuScreen(),
      StoreSettingsScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = _currentIndex == i;
                final hasBadge = i == 1 && _newOrderCount > 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon with badge
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  key: ValueKey(isActive),
                                  size: 24,
                                  color: isActive
                                      ? AppColors.primary
                                      : isDark
                                          ? AppColors.darkMuted
                                          : AppColors.lightMuted,
                                ),
                              ),
                              if (hasBadge)
                                Positioned(
                                  top: -5,
                                  right: -6,
                                  child: ScaleTransition(
                                    scale: _badgeScale,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _newOrderCount > 9
                                              ? '9+'
                                              : '$_newOrderCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Label
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.primary
                                  : isDark
                                      ? AppColors.darkMuted
                                      : AppColors.lightMuted,
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
