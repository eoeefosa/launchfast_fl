import 'dart:async';
import 'package:campuschow/providers/cart_provider.dart';
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/models/store.dart' as main_store;
import 'package:campuschow/models/menu_item.dart' as main_menu_item;
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
  String? _subscribedStoreId; // tracked so we can unsubscribe on dispose
  late AnimationController _badgeCtrl;
  late Animation<double> _badgeScale;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    if (userId == null) {
      debugPrint('[StoreMainNav] Ably init failed: No user ID');
      return;
    }

    debugPrint(
      '[StoreMainNav] Initializing real-time services for owner: $userId',
    );

    // Tell the provider who the owner is — all child screens will use this
    await storeProvider.setOwner(userId, linkedStoreId: auth.user?.adminStore);

    try {
      await ablyService.initAbly(userId);
      if (!mounted) return;

      // Listen for new orders via the order-update listener
      ablyService.addOrderListener(_onAblyOrderUpdate);

      // Subscribe to the owned store's orders channel
      // The ownedId is now guaranteed to be populated after the await above
      final ownedId = storeProvider.ownedStoreId;
      if (ownedId != null) {
        debugPrint('[StoreMainNav] Subscribing to store channels: $ownedId');
        await ablyService.subscribeToStoreOrders(ownedId);

        // Subscribe to the FCM topic for this store so background push
        // notifications (new order, payment confirmed) are delivered.
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
        channelId: NotificationService.orderChannelId,
      );

      // Also show a persistent in-app alert dialog so the owner doesn't miss it
      _showNewOrderAlert(orderId);

      // Play the alert sound
      _playAlertSound();
    }
  }

  Future<void> _playAlertSound() async {
    try {
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
              _onTabTapped(1); // Switch to Orders tab
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

          if (ownedStore == null) {
            return const Center(child: CircularProgressIndicator());
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
