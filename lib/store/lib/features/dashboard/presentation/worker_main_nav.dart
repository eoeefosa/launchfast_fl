import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';
import 'package:campuschow/store/lib/features/dashboard/presentation/order_screen.dart';
import 'package:campuschow/store/lib/features/dashboard/presentation/worker_dashboard.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'menu_screen.dart';

class WorkerMainNav extends StatefulWidget {
  const WorkerMainNav({super.key});

  @override
  State<WorkerMainNav> createState() => _WorkerMainNavState();
}

class _WorkerMainNavState extends State<WorkerMainNav>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _newOrderCount = 0;
  bool _ablyInitialized = false;

  late AnimationController _badgeCtrl;
  late Animation<double> _badgeScale;

  static const List<({String label, IconData icon, IconData activeIcon})>
  _navItems = [
    (
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    (
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
    ),
    (
      label: 'Menu',
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu_rounded,
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _badgeScale = Tween<double>(
      begin: 0.85,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initAbly();
    });
  }

  Future<void> _initAbly() async {
    if (_ablyInitialized || !mounted) return;
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final userId = auth.user?.id;
    final adminStoreId = auth.user?.adminStore;

    if (userId == null) return;

    if (adminStoreId != null) {
      storeProvider.setActiveStoreId(adminStoreId);
    }

    try {
      await ablyService.initAbly(userId);
      if (!mounted) return;

      // Listen for orders
      ablyService.addOrderListener((orderId, status) {
        if (status == OrderStatus.pending && mounted) {
          setState(() => _newOrderCount++);
          _badgeCtrl.repeat(reverse: true);
        }
      });

      // Find the store assigned to this worker and subscribe
      if (storeProvider.stores.isEmpty) {
        await storeProvider.refreshData();
      }
      
      if (!mounted) return;

      final activeId = storeProvider.activeStoreId;
      if (activeId != null) {
        ablyService.subscribeToStoreOrders(activeId);
      }

      _ablyInitialized = true;
    } catch (_) {}
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) _newOrderCount = 0; // Clear badge when viewing orders
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      const WorkerDashboardHome(),
      const StoreOrdersScreen(),
      const StoreMenuScreen(),
      const Center(child: Text('Profile Settings (Coming Soon)')),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          height: 70,
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = _currentIndex == i;
              final hasBadge = i == 1 && _newOrderCount > 0;

              return Expanded(
                child: InkWell(
                  onTap: () => _onTabTapped(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 24,
                            color: isActive
                                ? AppColors.primary
                                : isDark
                                ? AppColors.darkMuted
                                : AppColors.lightMuted,
                          ),
                          if (hasBadge)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: ScaleTransition(
                                scale: _badgeScale,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$_newOrderCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.primary
                              : isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
