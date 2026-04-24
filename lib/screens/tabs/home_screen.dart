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
import '../../widgets/home/store_section.dart';
import '../../widgets/home/menu_grouped_list.dart';
import '../../widgets/home/category_selector.dart';
import '../../widgets/home/cart_bar.dart';
import '../../services/ably_service.dart';


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
      _activeStoreId = storeProvider.stores.first.id;
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

  void _onSearchChanged(String query) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query);
      }
    });
  }

  void _onStoreSelected(String storeId) {
    setState(() {
      _activeStoreId = storeId;
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    // final authProvider = context.watch<AuthProvider>();
    // final user = authProvider.user;

    final storeProvider = context.watch<StoreProvider>();
    if (storeProvider.isLoading && storeProvider.stores.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }

    if (storeProvider.stores.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No stores available')),
      );
    }

    final activeStore = storeProvider.stores.firstWhere(
      (s) => s.id == _activeStoreId,
      orElse: () => storeProvider.stores.isNotEmpty
          ? storeProvider.stores.first
          : throw Exception('No stores available'),
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
    final categories = storeProvider.menuItems
        .map((item) => item.category)
        .toSet()
        .toList();
    for (var cat in categories) {
      final items = filteredItems.where((i) => i.category == cat).toList();
      if (items.isNotEmpty) groupedItems[cat] = items;
    }

    final accentColor = Color(int.parse(activeStore.accentColor.replaceFirst('#', '0xFF')));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on, size: 18, color: Colors.black54),
                            SizedBox(width: 4),
                            Text('Deliver to Home', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Now',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // "Restaurants" header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Restaurants',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                // StoreSection with fade + slide animation
                SliverToBoxAdapter(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: StoreSection(
                      stores: storeProvider.stores,
                      activeStoreId: _activeStoreId,
                      onStoreSelected: _onStoreSelected,
                      accentColor: accentColor,
                    ),
                  ),
                ),
                // Sticky category selector
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    child: Container(
                      color: const Color(0xFFF7F7F7),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CategorySelector(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                      ),
                    ),
                  ),
                ),
                // ── FIX: Use _AnimatedMenuList instead of wrapping MenuGroupedList
                // (a sliver) inside SliverToBoxAdapter → TweenAnimationBuilder → Transform,
                // which caused the RenderTransform/RenderSliverList type mismatch.
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 120),
                  sliver: _AnimatedMenuList(
                    groupedItems: groupedItems,
                    accentColor: accentColor,
                    onAdd: (item) => _handleAddItem(context, item),
                    emptyMessage: filteredItems.isEmpty
                        ? 'No items found. Try a different search or category.'
                        : storeProvider.error,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(30),
                  child: CartBar(accent: accentColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddItem(BuildContext context, MenuItem item) {
    final cartProvider = context.read<CartProvider>();
    if (item.category == 'Swallow' || (item.addonIds != null && item.addonIds!.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select options for this item')),
      );
      context.push('/item/${item.id}');
    } else {
      final success = cartProvider.addToCart(item: item, quantity: 1);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} added to cart')),
        );
      }
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
          content: const Text(
              'Your cart contains items from another store. Clear cart and add this item?'),
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
          content: const Text(
              'Your cart contains items from another store. Clear cart and add this item?'),
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

// ── Sliver-aware animated wrapper for MenuGroupedList ─────────────────────────
//
// Root cause of the original crash:
//   SliverToBoxAdapter → TweenAnimationBuilder → Transform expects a RenderBox
//   child, but MenuGroupedList renders a SliverList (RenderSliverList) internally.
//   RenderTransform cannot parent a RenderSliver — hence the assertion.
//
// Fix:
//   Use SliverFadeTransition (sliver-aware opacity animation) as the outermost
//   wrapper so the sliver protocol is respected end-to-end. The AnimationController
//   drives a 0→1 fade-in on first build, giving the same entry feel as before.
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedMenuList extends StatefulWidget {
  final Map<String, List<MenuItem>> groupedItems;
  final Color accentColor;
  final void Function(MenuItem) onAdd;
  final String? emptyMessage;

  const _AnimatedMenuList({
    required this.groupedItems,
    required this.accentColor,
    required this.onAdd,
    this.emptyMessage,
  });

  @override
  State<_AnimatedMenuList> createState() => _AnimatedMenuListState();
}

class _AnimatedMenuListState extends State<_AnimatedMenuList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SliverFadeTransition is sliver-aware — it wraps a sliver child correctly,
    // unlike Opacity/Transform which expect RenderBox children.
    return SliverFadeTransition(
      opacity: _opacity,
      sliver: MenuGroupedList(
        groupedItems: widget.groupedItems,
        accentColor: widget.accentColor,
        onAdd: widget.onAdd,
        emptyMessage: widget.emptyMessage,
      ),
    );
  }
}

// ── Sticky category header delegate ──────────────────────────────────────────
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryHeaderDelegate({required this.child});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}