import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/menu_item.dart';
import '../../models/notification_item.dart';
import '../../models/order.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/featured_meals.dart';
import '../../widgets/home/store_section.dart';
import '../../widgets/home/store_banner.dart';
import '../../widgets/home/menu_grouped_list.dart';
import '../../widgets/home/category_selector.dart';
import '../../widgets/home/cart_bar.dart';
import '../../services/ably_service.dart';

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

  late final void Function(String) _roleListener;
  late final void Function(Map<String, dynamic>) _notificationListener;
  late final void Function(String, OrderStatus) _ablyOrderListener;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAblyListeners();
  }

  void _initializeData() {
    final storeProvider = context.read<StoreProvider>();
    if (storeProvider.stores.isNotEmpty) {
      _activeStoreId = storeProvider.stores[0].id;
    }
  }

  void _setupAblyListeners() {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId != null) {
      ablyService.initAbly(userId);
      _roleListener = (String newRole) {
        if (mounted) context.read<AuthProvider>().updateRole(newRole);
      };
      ablyService.addRoleListener(_roleListener);

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

  void _onSearchChanged(String query) => setState(() => _searchQuery = query);

  void _onStoreSelected(String storeId) {
    setState(() {
      _activeStoreId = storeId;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Role-based redirection
    if (user?.role == 'SUPER_ADMIN') return const AdminMainNav();
    if (user?.role == 'STORE_OWNER') return const StoreMainNav();
    if (user?.role == 'STORE_WORKER') return const WorkerMainNav();
    if (user?.role == 'RIDER') return const RiderDashboard();

    final storeProvider = context.watch<StoreProvider>();
    if (storeProvider.isLoading && storeProvider.stores.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }

    final activeStore = storeProvider.stores.firstWhere(
      (s) => s.id == _activeStoreId,
      orElse: () => storeProvider.stores.isNotEmpty ? storeProvider.stores[0] : storeProvider.stores[0],
    );

    final filteredItems = storeProvider.menuItems.where((item) {
      final matchesStore = item.storeId == _activeStoreId;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesStore && matchesSearch && matchesCategory;
    }).toList();

    final groupedItems = <String, List<MenuItem>>{};
    final categories = ['Rice', 'Swallow', 'Soup', 'Others', 'Drinks'];
    for (var cat in categories) {
      final items = filteredItems.where((i) => i.category == cat).toList();
      if (items.isNotEmpty) groupedItems[cat] = items;
    }

    final accentColor = Color(int.parse(activeStore.accentColor.replaceFirst('#', '0xFF')));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (isIOS)
                  CupertinoSliverRefreshControl(
                    onRefresh: () => storeProvider.refreshData(),
                  ),
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
                      onAdd: (item) => _handleAddItem(context, item),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: CategorySelector(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StoreSection(
                    stores: storeProvider.stores,
                    activeStoreId: _activeStoreId,
                    onStoreSelected: _onStoreSelected,
                    accentColor: accentColor,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: StoreBanner(store: activeStore),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120),
                  sliver: MenuGroupedList(
                    groupedItems: groupedItems,
                    accentColor: accentColor,
                    onAdd: (item) => _handleAddItem(context, item),
                    emptyMessage: storeProvider.error,
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

  void _handleAddItem(BuildContext context, MenuItem item) {
    final cartProvider = context.read<CartProvider>();
    if (item.category == 'Swallow' || (item.addonIds != null && item.addonIds!.isNotEmpty)) {
      context.push('/item/${item.id}');
    } else {
      final success = cartProvider.addToCart(item: item, quantity: 1);
      if (!success) _showClearCartDialog(context, item);
    }
  }

  void _showClearCartDialog(BuildContext context, MenuItem item) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Start new order?'),
          content: const Text('Your cart contains items from another store. Clear cart and add this item?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                context.read<CartProvider>().forceClearAndAdd(item: item, quantity: 1);
                Navigator.pop(context);
              },
              child: const Text('Clear & Add'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Start new order?'),
          content: const Text('Your cart contains items from another store. Clear cart and add this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<CartProvider>().forceClearAndAdd(item: item, quantity: 1);
                Navigator.pop(context);
              },
              child: const Text('Clear & Add'),
            ),
          ],
        ),
      );
    }
  }
}
