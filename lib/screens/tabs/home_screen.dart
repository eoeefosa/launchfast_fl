import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/menu_item.dart';
import '../../models/notification_item.dart';
import '../../models/order.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/featured_meals.dart';
import '../../widgets/home/store_tabs.dart';
import '../../widgets/home/store_banner.dart';
import '../../widgets/home/menu_item_card.dart';
import '../../widgets/home/cart_bar.dart';
import '../../services/ably_service.dart';

import '../../providers/auth_provider.dart';
import '../dashboards/admin/admin_main_nav.dart';
import '../dashboards/store/store_main_nav.dart';
import '../dashboards/rider/rider_dashboard.dart';
import '../dashboards/worker/worker_main_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeStoreId = '';
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Keep a reference so we can remove it in dispose
  late final void Function(String) _roleListener;
  late final void Function(Map<String, dynamic>) _notificationListener;
  late final void Function(String, OrderStatus) _ablyOrderListener;

  @override
  void initState() {
    super.initState();
    final storeProvider = context.read<StoreProvider>();
    if (storeProvider.stores.isNotEmpty) {
      _activeStoreId = storeProvider.stores[0].id;
    }

    // ─── Ably: listen for instant role updates from the admin ─────────
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId != null) {
      ablyService.initAbly(userId);
      _roleListener = (String newRole) {
        if (mounted) {
          context.read<AuthProvider>().updateRole(newRole);
        }
      };
      ablyService.addRoleListener(_roleListener);

      // Listen for generic notifications
      _notificationListener = (Map<String, dynamic> payload) {
        if (mounted) {
          final item = NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: payload['title'] ?? 'New Notification',
            message: payload['message'] ?? '',
            type: NotificationType.values.firstWhere(
              (t) => t.toString().split('.').last == payload['type'],
              orElse: () => NotificationType.serverAlert,
            ),
            timestamp: DateTime.now(),
            metadata: Map<String, dynamic>.from(payload['metadata'] ?? {}),
          );
          context.read<NotificationProvider>().addNotification(item);
        }
      };
      ablyService.addNotificationListener(_notificationListener);

      // Listen for order updates specifically to create notifications
      _ablyOrderListener = (String orderId, OrderStatus status) {
        if (mounted) {
          final item = NotificationItem(
            id: 'order-$orderId-${status.name}',
            title: 'Order Updated',
            message: 'Your order #$orderId is now ${status.name.toUpperCase()}',
            type: NotificationType.orderUpdate,
            timestamp: DateTime.now(),
            metadata: {'orderId': orderId, 'status': status.name},
          );
          context.read<NotificationProvider>().addNotification(item);
        }
      };
      ablyService.addOrderListener(_ablyOrderListener);
    } else {
      // No user yet — register a no-op so dispose is safe
      _roleListener = (_) {};
      _notificationListener = (_) {};
      _ablyOrderListener = (_, _) {};
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    ablyService.removeRoleListener(_roleListener);
    ablyService.removeNotificationListener(_notificationListener);
    ablyService.removeOrderListener(_ablyOrderListener);
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onStoreSelected(String storeId) {
    setState(() {
      _activeStoreId = storeId;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Role-based UI redirection
    if (user?.role == 'SUPER_ADMIN') return const AdminMainNav();
    if (user?.role == 'STORE_OWNER') return const StoreMainNav();
    if (user?.role == 'STORE_WORKER') return const WorkerMainNav();
    if (user?.role == 'RIDER') return const RiderDashboard();

    if (storeProvider.isLoading && storeProvider.stores.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeStore = storeProvider.stores.firstWhere(
      (s) => s.id == _activeStoreId,
      orElse: () => storeProvider.stores[0],
    );

    final filteredItems = storeProvider.menuItems.where((item) {
      final matchesStore = item.storeId == _activeStoreId;
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      
      return matchesStore && matchesSearch && matchesCategory;
    }).toList();

    // Group items by category
    final categories = ['Rice', 'Swallow', 'Soup', 'Others'];
    final groupedItems = <String, List<MenuItem>>{};
    for (var cat in categories) {
      final items = filteredItems.where((i) => i.category == cat).toList();
      if (items.isNotEmpty) groupedItems[cat] = items;
    }

    final accentColor = Color(
      int.parse(activeStore.accentColor.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHeader(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                  ),
                ),
                if (_searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: FeaturedMeals(
                      items: storeProvider.menuItems.where((i) => i.popular).toList(),
                      onAdd: (item) => _handleAddItem(context, cartProvider, item),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildCategoryChip(
                            'All',
                            Icons.restaurant_rounded,
                            _selectedCategory == 'All',
                            () => setState(() => _selectedCategory = 'All'),
                          ),
                          const SizedBox(width: 12),
                          _buildCategoryChip(
                            'Rice',
                            Icons.rice_bowl_rounded,
                            _selectedCategory == 'Rice',
                            () => setState(() => _selectedCategory = 'Rice'),
                          ),
                          const SizedBox(width: 12),
                          _buildCategoryChip(
                            'Swallow',
                            Icons.cookie_rounded,
                            _selectedCategory == 'Swallow',
                            () => setState(() => _selectedCategory = 'Swallow'),
                          ),
                          const SizedBox(width: 12),
                          _buildCategoryChip(
                            'Soup',
                            Icons.soup_kitchen_rounded,
                            _selectedCategory == 'Soup',
                            () => setState(() => _selectedCategory = 'Soup'),
                          ),
                          const SizedBox(width: 12),
                          _buildCategoryChip(
                            'Drinks',
                            Icons.local_drink_rounded,
                            _selectedCategory == 'Drinks',
                            () => setState(() => _selectedCategory = 'Drinks'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Our Stores',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/stores'),
                          child: Text(
                            'See All',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StoreTabs(
                    stores: storeProvider.stores,
                    activeStoreId: _activeStoreId,
                    onSelect: _onStoreSelected,
                  ),
                ),
                SliverToBoxAdapter(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: StoreBanner(store: activeStore),
                        ),
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  sliver: filteredItems.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              storeProvider.error ?? "No items found",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final category = groupedItems.keys.elementAt(index);
                              final items = groupedItems[category]!;
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 400 + (index * 100)),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 30 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 24,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        category.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                    ...items.map(
                                      (item) => MenuItemCard(
                                        item: item,
                                        accent: accentColor,
                                        onAdd: () => _handleAddItem(context, cartProvider, item),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: groupedItems.length,
                          ),
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CartBar(accent: accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[800],
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddItem(BuildContext context, CartProvider cartProvider, MenuItem item) {
    if (item.category == 'Swallow' ||
        (item.addonIds != null &&
            item.addonIds!.isNotEmpty)) {
      context.push('/item/${item.id}');
    } else {
      final success = cartProvider.addToCart(
        item: item,
        quantity: 1,
      );
      if (!success) {
        _showClearCartDialog(context, item);
      }
    }
  }

  void _showClearCartDialog(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start new order?'),
        content: const Text(
          'Your cart contains items from another store. Clear cart and add this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartProvider>().forceClearAndAdd(
                item: item,
                quantity: 1,
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Clear & Add',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

