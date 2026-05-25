import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/ably_service.dart';
import '../../widgets/home/cart_bar.dart';
import '../../widgets/home/category_selector.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/item_options_sheet.dart';
import '../../widgets/home/store_section.dart';
import '../../widgets/home/home_skeleton.dart';
import '../../widgets/home/category_header_delegate.dart';
import '../../widgets/home/fade_slide_in.dart';
import '../../widgets/home/animated_menu_list.dart';
import 'components/home_empty_body.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const List<String> _kCategoryOrder = [
  'Rice & Pasta',
  'Swallow & Soup',
  'Drinks',
  'Side',
  'Protein',
  'Snacks & Pastries',
  'Others',
];

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeStoreId = '';
  String _selectedCategory = 'All';
  late final void Function(String) _roleListener;

  @override
  void initState() {
    super.initState();
    _initActiveStore();
    _setupAblyRoleListener();
  }

  @override
  void dispose() {
    ablyService.removeRoleListener(_roleListener);
    super.dispose();
  }

  void _initActiveStore() {
    final stores = context.read<StoreProvider>().stores;
    if (stores.isNotEmpty) {
      _activeStoreId = stores.first.id;
    }
  }

  void _setupAblyRoleListener() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      _roleListener = (String newRole) {
        if (mounted) context.read<AuthProvider>().updateRole(newRole);
      };
      ablyService.addRoleListener(_roleListener);
    } else {
      _roleListener = (_) {};
    }
  }

  void _onStoreSelected(String storeId) {
    setState(() {
      _activeStoreId = storeId;
      _selectedCategory = 'All';
    });
  }

  List<MenuItem> _filteredItems(
    StoreProvider provider,
    String storeId,
    String category,
  ) {
    return provider.menuItems.where((item) {
      final matchesStore = item.storeId == storeId;
      final matchesCategory = category == 'All' || item.category == category;
      final isNotSoup = item.type != 'soup';
      return matchesStore && matchesCategory && isNotSoup;
    }).toList();
  }

  Map<String, List<MenuItem>> _groupedItems(
    List<MenuItem> filtered,
    String storeId,
    StoreProvider provider,
  ) {
    final present =
        provider.menuItems
            .where((item) => item.storeId == storeId && item.type != 'soup')
            .map((item) => item.category)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort((a, b) {
            final indexA = _kCategoryOrder.indexOf(a);
            final indexB = _kCategoryOrder.indexOf(b);
            if (indexA == -1 && indexB == -1) return a.compareTo(b);
            if (indexA == -1) return 1;
            if (indexB == -1) return -1;
            return indexA.compareTo(indexB);
          });

    return {
      for (final cat in present)
        if (filtered.where((i) => i.category == cat).isNotEmpty)
          cat: filtered.where((i) => i.category == cat).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use AppColors directly for scaffold background
    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    if (_activeStoreId.isEmpty && storeProvider.stores.isNotEmpty) {
      _activeStoreId = storeProvider.stores.first.id;
    }

    if (storeProvider.isLoading && storeProvider.stores.isEmpty) {
      return const HomeSkeleton();
    }

    if (storeProvider.stores.isEmpty) {
      return HomeEmptyBody(
        message: storeProvider.error,
        onRetry: storeProvider.refreshData,
      );
    }

    final activeStore = storeProvider.stores.firstWhere(
      (s) => s.id == _activeStoreId,
      orElse: () => storeProvider.stores.first,
    );

    final filtered = _filteredItems(
      storeProvider,
      _activeStoreId,
      _selectedCategory,
    );
    final grouped = _groupedItems(filtered, _activeStoreId, storeProvider);
    final categories = ['All', ...grouped.keys];
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: scaffoldBg, // premium background
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (isIOS)
                  CupertinoSliverRefreshControl(
                    onRefresh: storeProvider.refreshData,
                  ),

                const SliverToBoxAdapter(child: HomeHeader()),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Restaurants',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor, // readable on scaffold bg
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: StoreSection(
                      stores: storeProvider.stores,
                      activeStoreId: _activeStoreId,
                      onStoreSelected: _onStoreSelected,
                      accentColor: activeStore.accentColor,
                    ),
                  ),
                ),

                SliverPersistentHeader(
                  key: ValueKey(_activeStoreId),
                  pinned: true,
                  delegate: CategoryHeaderDelegate(
                    backgroundColor: scaffoldBg, // header matches scaffold
                    child: CategorySelector(
                      selectedCategory: _selectedCategory,
                      categories: categories,
                      onCategorySelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 120),
                  sliver: AnimatedMenuList(
                    key: ValueKey(_activeStoreId),
                    groupedItems: grouped,
                    accentColor: activeStore.accentColor,
                    onAdd: (item) => _handleAddItem(context, item),
                    emptyMessage: filtered.isEmpty
                        ? 'No items found in this category.'
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
                child: CartBar(accent: activeStore.accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddItem(BuildContext context, MenuItem item) async {
    final cartProvider = context.read<CartProvider>();
    final store = context.read<StoreProvider>().stores.firstWhere(
      (s) => s.id == item.storeId,
    );

    final needsSheet =
        item.type == 'main' ||
        item.type == 'swallow' ||
        (item.compatibleWith?.isNotEmpty ?? false) ||
        (item.addonIds?.isNotEmpty ?? false) ||
        item.sizes.isNotEmpty;

    if (needsSheet) {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            ItemOptionsSheet(item: item, accentColor: store.accentColor),
      );

      if (!context.mounted) return;

      if (result == 'CLEAR_REQUIRED') {
        _showClearCartDialog(context, item);
      } else if (result == 'SUCCESS') {
        _showAddedSnackBar(context, item.name);
      }
    } else {
      final success = cartProvider.addToCart(item: item, quantity: 1);
      if (!context.mounted) return;
      if (success) {
        _showAddedSnackBar(context, item.name);
      } else {
        _showClearCartDialog(context, item);
      }
    }
  }

  void _showAddedSnackBar(BuildContext context, String itemName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snackBarBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final snackBarText = isDark ? AppColors.darkText : AppColors.lightText;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(itemName, style: TextStyle(color: snackBarText)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        backgroundColor: snackBarBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, MenuItem item) {
    void clearAndAdd() {
      context.read<CartProvider>().forceClearAndAdd(item: item, quantity: 1);
      Navigator.of(context).pop();
    }

    const title = 'Start new order?';
    const body =
        'Your cart contains items from another store. Clear cart and add this item?';

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text(title),
          content: const Text(body),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: clearAndAdd,
              child: const Text('Clear & Add'),
            ),
          ],
        ),
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dialogBg = isDark
          ? AppColors.darkSurface
          : AppColors.lightBackground;
      final textColor = isDark ? AppColors.darkText : AppColors.lightText;

      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
          ),
          content: Text(body, style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightMuted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // destructive action kept red
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: clearAndAdd,
              child: const Text('Clear & Add'),
            ),
          ],
        ),
      );
    }
  }
}
