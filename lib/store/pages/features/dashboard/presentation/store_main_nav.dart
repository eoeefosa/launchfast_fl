import 'dart:async';
import 'dart:io';
import 'package:campuschow/providers/cart_provider.dart';
import 'package:campuschow/store/pages/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:campuschow/store/pages/features/store/presentation/store_provider.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/pages/core/theme/app_colors.dart';
import 'package:campuschow/store/pages/core/widgets/shimmer_placeholder.dart';
import 'package:campuschow/store/pages/features/auth/presentation/auth_provider.dart';
import 'package:campuschow/store/pages/core/services/ably_service.dart';
import 'package:campuschow/store/pages/features/orders/data/order_model.dart';
import 'package:campuschow/models/store.dart' as main_store;
import 'package:campuschow/models/menu_item.dart' as main_menu_item;
import 'package:campuschow/widgets/common/liquid_glass_bottom_bar.dart';
import 'main_dashboard.dart';
import 'order_screen.dart';
import 'menu_screen.dart';
import 'store_history_screen.dart';
import 'store_setting.dart';
import 'store_order_detail_screen.dart';

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
  String? _subscribedStoreId; // tracked so we can unsubscribe on dispose
  late AnimationController _badgeCtrl;
  late Animation<double> _badgeScale;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _pendingOrderIds = {};
  final Map<String, Timer> _pendingOrderTimers = {};

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
      label: 'History',
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
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
      StoreHistoryScreen(),
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
    if (userId == null) {
      debugPrint('[StoreMainNav] Ably init failed: No user ID');
      return;
    }

    debugPrint(
      '[StoreMainNav] Initializing real-time services for owner: $userId',
    );

    // 1. Tell the provider who the owner is — all child screens will use this
    await storeProvider.setOwner(userId, linkedStoreId: auth.user?.adminStore);
    if (!mounted) return;

    // 2. Register listener BEFORE connecting so we never miss an event
    ablyService.addOrderListener(_onAblyOrderUpdate);

    try {
      await ablyService.initAbly(userId);
      if (!mounted) return;

      // 3. Subscribe to the owned store's orders channel.
      //    We explicitly remove the old key first so that even if Ably was
      //    already connected (initAbly returned early), we force a fresh
      //    channel subscription. This fixes the "already connected" no-op bug.
      final ownedId = storeProvider.ownedStoreId;
      if (ownedId != null) {
        debugPrint('[StoreMainNav] Subscribing to store channels: $ownedId');
        final storeChannelKey = 'store:$ownedId:orders:new-order';
        final updateChannelKey = 'store:$ownedId:orders:order-update';
        // Force fresh subscription by removing old keys
        ablyService.removeSubscriptionKey(storeChannelKey);
        ablyService.removeSubscriptionKey(updateChannelKey);
        await ablyService.subscribeToStoreOrders(ownedId);

        // 4. Subscribe to the FCM topic for background push notifications
        _subscribedStoreId = ownedId;
        unawaited(notificationService.subscribeToStoreAdminTopic(ownedId));
      } else {
        debugPrint(
          '[StoreMainNav] Warning: No owned store ID found for owner $userId',
        );
      }

      _ablyInitialized = true;
      debugPrint('[StoreMainNav] Real-time services initialized successfully');
    } catch (e) {
      debugPrint('[StoreMainNav] Real-time services init error: $e');
    }
  }

  void _onAblyOrderUpdate(String orderId, OrderStatus status) {
    if (status == OrderStatus.pending) {
      if (mounted) {
        setState(() => _newOrderCount++);
        _badgeCtrl.repeat(reverse: true);

        // Trigger a local notification for foreground alert
        notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: 'New Order Received! 🚀',
          body: 'You have a new pending order ($orderId). Tap to view.',
          payload: 'store_order_$orderId',
          channelId: kOrderChannelId,
        );

        // Also show a persistent in-app alert dialog so the owner doesn't miss it
        _showNewOrderAlert(orderId);
      }

      // Track pending orders and set reminder timer
      if (!_pendingOrderIds.contains(orderId)) {
        _pendingOrderIds.add(orderId);
        _playAlertSound();

        _pendingOrderTimers[orderId]?.cancel();
        _pendingOrderTimers[orderId] = Timer.periodic(
          const Duration(minutes: 5),
          (timer) {
            if (_pendingOrderIds.contains(orderId)) {
              _playAlertSound();
            } else {
              timer.cancel();
              _pendingOrderTimers.remove(orderId);
            }
          },
        );
      }
    } else {
      // If the order has been updated to any non-pending status, stop alert
      _pendingOrderIds.remove(orderId);
      _pendingOrderTimers[orderId]?.cancel();
      _pendingOrderTimers.remove(orderId);

      if (_pendingOrderIds.isEmpty) {
        _audioPlayer.stop();
      }
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/order_sound.mp3'));
    } catch (e) {
      debugPrint('[AudioPlayer] Error playing sound: $e');
    }
  }

  void _showNewOrderAlert(String orderId) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.orange),
            SizedBox(width: 10),
            Text('New Order!'),
          ],
        ),
        content: Text(
          'You have received a new order (#${orderId.substring(orderId.length - 6).toUpperCase()}).\n\nWould you like to view it now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => StoreOrderDetailScreen(orderId: orderId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View Order'),
          ),
        ],
      ),
    );
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
    _audioPlayer.dispose();
    for (final timer in _pendingOrderTimers.values) {
      timer.cancel();
    }
    _pendingOrderTimers.clear();
    _pendingOrderIds.clear();

    if (_ablyInitialized) {
      ablyService.removeOrderListener(_onAblyOrderUpdate);
    }
    // Unsubscribe from store admin FCM topic to prevent ghost notifications
    if (_subscribedStoreId != null) {
      notificationService.unsubscribeFromStoreAdminTopic(_subscribedStoreId!);
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

          // 1. Show spinner while provider is doing its initial work
          if (storeProvider.isLoading && ownedStore == null) {
            return Scaffold(
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              body: const _StoreOwnerLoadingSkeleton(),
            );
          }

          // 2. Handle cases where no store is linked to this account
          if (ownedStore == null) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 80,
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Store Linked',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'We couldn\'t find a store associated with your account. If you just applied, it might be pending approval.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => auth.refreshUser(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Refresh Profile',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => auth.logout(),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              // Sync pricing from store provider to cart provider
              WidgetsBinding.instance.addPostFrameCallback((_) {
                cartProvider.updatePricing(
                  meatPrices: storeProvider.meatPrices,
                  saladPrice: storeProvider.saladPrice,
                  allMenuItems: storeProvider.menuItems
                      .map((m) => main_menu_item.MenuItem.fromJson(m.toJson()))
                      .toList(),
                  allStores: storeProvider.stores
                      .map((s) => main_store.Store.fromJson(s.toJson()))
                      .toList(),
                );
              });

              return IndexedStack(index: _currentIndex, children: _pages);
            },
          );
        },
      ),
      bottomNavigationBar: Platform.isIOS
          ? LiquidGlassBottomBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                return LiquidGlassNavItem(
                  icon: item.icon,
                  activeIcon: item.activeIcon,
                  label: item.label,
                  badgeCount: i == 1 ? _newOrderCount : null,
                );
              }),
            )
          : Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
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
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
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

class _StoreOwnerLoadingSkeleton extends StatelessWidget {
  const _StoreOwnerLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerPlaceholder(width: 180, height: 28, borderRadius: 8),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: const Row(
                children: [
                  ShimmerPlaceholder(width: 50, height: 50, borderRadius: 25),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder(
                          width: 140,
                          height: 16,
                          borderRadius: 6,
                        ),
                        SizedBox(height: 8),
                        ShimmerPlaceholder(
                          width: 120,
                          height: 12,
                          borderRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const ShimmerPlaceholder(width: 160, height: 22, borderRadius: 8),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: List.generate(
                4,
                (_) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(
                        width: 20,
                        height: 20,
                        borderRadius: 10,
                      ),
                      Spacer(),
                      ShimmerPlaceholder(
                        width: 70,
                        height: 22,
                        borderRadius: 8,
                      ),
                      SizedBox(height: 8),
                      ShimmerPlaceholder(
                        width: 90,
                        height: 12,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const ShimmerPlaceholder(width: 140, height: 22, borderRadius: 8),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: const Row(
                  children: [
                    ShimmerPlaceholder(width: 40, height: 40, borderRadius: 12),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerPlaceholder(
                            width: 120,
                            height: 14,
                            borderRadius: 4,
                          ),
                          SizedBox(height: 8),
                          ShimmerPlaceholder(
                            width: 90,
                            height: 12,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    ShimmerPlaceholder(width: 72, height: 24, borderRadius: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
