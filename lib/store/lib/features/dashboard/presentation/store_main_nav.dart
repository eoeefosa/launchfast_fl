import 'dart:async';
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'main_dashboard.dart';
import 'order_screen.dart';
import 'menu_screen.dart';
import 'store_setting.dart';

class StoreMainNav extends StatefulWidget {
  const StoreMainNav({super.key});

  @override
  State<StoreMainNav> createState() => _StoreMainNavState();
}

class _StoreMainNavState extends State<StoreMainNav>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Pages are built once and kept alive via IndexedStack
  late final List<Widget> _pages;

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
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
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

    _pages = [
      StoreDashboardHome(),
      StoreOrdersScreen(),
      StoreMenuScreen(),
      StoreSettingsScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initAbly();
    });
  }

  Future<void> _initAbly() async {
    if (_ablyInitialized || !mounted) return;
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;

    // Tell the provider who the owner is — all child screens will use this
    await storeProvider.setOwner(userId);

    try {
      await ablyService.initAbly(userId);
      if (!mounted) return;

      // Listen for new orders via the order-update listener
      ablyService.addOrderListener(_onAblyOrderUpdate);

      // Subscribe to the owned store's orders channel
      // The ownedId is now guaranteed to be populated after the await above
      final ownedId = storeProvider.ownedStoreId;
      if (ownedId != null) {
        await ablyService.subscribeToStoreOrders(ownedId);
      }

      _ablyInitialized = true;
    } catch (_) {}
  }

  void _onAblyOrderUpdate(String orderId, OrderStatus status) {
    // When a new PENDING order arrives, bump the badge on Orders tab
    if (status == OrderStatus.pending && mounted) {
      setState(() => _newOrderCount++);
      _badgeCtrl.repeat(reverse: true);

      // Trigger a local notification for foreground alert
      notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'New Order Received! 🚀',
        body: 'You have a new pending order ($orderId). Tap to view.',
        payload: 'order_$orderId',
      );
    }
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
    if (_ablyInitialized) {
      ablyService.removeOrderListener(_onAblyOrderUpdate);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final navBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      body: Consumer2<AuthProvider, StoreProvider>(
        builder: (context, auth, storeProvider, child) {
          final ownedStore = storeProvider.ownedStore;

          if (ownedStore == null || !ownedStore.isApproved) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions, size: 80, color: Colors.orange),
                    const SizedBox(height: 24),
                    const Text(
                      'Approval Pending',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your store "${ownedStore?.name ?? 'your store'}" is currently being reviewed by our administrators. You will be notified once it is approved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (auth.user?.id != null) {
                          storeProvider.setOwner(auth.user!.id);
                        } else {
                          storeProvider.refreshData();
                        }
                      },
                      child: const Text('Check Status'),
                    ),
                    TextButton(
                      onPressed: () => auth.logout(),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            );
          }

          return IndexedStack(
            index: _currentIndex,
            children: _pages,
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
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
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.1)
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
