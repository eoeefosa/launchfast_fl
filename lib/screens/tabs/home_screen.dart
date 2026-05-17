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

/// Canonical display order for menu categories.
/// "Soup" is intentionally absent — it is only shown as an add-on inside
/// swallow items, never as a standalone orderable category.
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
  // ── State ──────────────────────────────────────────────────────────────────

  String _activeStoreId = '';
  String _selectedCategory = 'All';

  // Typed as the exact function signature expected by AblyService so the
  // listener reference is stable across add/remove calls.
  late final void Function(String) _roleListener;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

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

  // ── Initialisation helpers ─────────────────────────────────────────────────

  /// Pre-selects the first available store so the UI is never blank on launch.
  void _initActiveStore() {
    final stores = context.read<StoreProvider>().stores;
    if (stores.isNotEmpty) {
      _activeStoreId = stores.first.id;
    }
  }

  /// Registers a real-time role-change listener via Ably.
  /// Falls back to a no-op when the user is not authenticated.
  void _setupAblyRoleListener() {
    final userId = context.read<AuthProvider>().user?.id;

    if (userId != null) {
      _roleListener = (String newRole) {
        if (mounted) context.read<AuthProvider>().updateRole(newRole);
      };
      ablyService.addRoleListener(_roleListener);
    } else {
      // No-op placeholder keeps the field non-null so dispose() is always safe.
      _roleListener = (_) {};
    }
  }

  // ── Callbacks ──────────────────────────────────────────────────────────────

  void _onStoreSelected(String storeId) {
    setState(() {
      _activeStoreId = storeId;
      _selectedCategory = 'All'; // reset filter on store change
    });
  }

  // ── Data derivation ────────────────────────────────────────────────────────

  /// Returns menu items visible for [storeId] under [category], excluding
  /// standalone soup items (which only appear as swallow add-ons).
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

  /// Builds a sorted, grouped map of category → items.
  ///
  /// Categories present in [_kCategoryOrder] appear first; unknown categories
  /// are appended alphabetically.
  Map<String, List<MenuItem>> _groupedItems(
    List<MenuItem> filtered,
    String storeId,
    StoreProvider provider,
  ) {
    // Derive the ordered category list from actual data, not a hard-coded set.
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();

    // Auto-select the first store when stores load after mount (e.g. after
    // a refresh) and nothing is selected yet.
    if (_activeStoreId.isEmpty && storeProvider.stores.isNotEmpty) {
      // Direct assignment — no setState needed here because this is inside
      // build() and the frame is not yet committed.
      _activeStoreId = storeProvider.stores.first.id;
    }

    // ── Loading skeleton ───────────────────────────────────────────────────
    if (storeProvider.isLoading && storeProvider.stores.isEmpty) {
      return const HomeSkeleton();
    }

    // ── Empty / error state ────────────────────────────────────────────────
    if (storeProvider.stores.isEmpty) {
      return HomeEmptyBody(
        message: storeProvider.error,
        onRetry: storeProvider.refreshData,
      );
    }

    // ── Loaded state ───────────────────────────────────────────────────────
    // firstWhere is safe: stores is non-empty and _activeStoreId is always
    // set to a valid id above.
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

    // Sorted category list for the selector — derived from grouped keys so it
    // exactly mirrors what is visible in the list.
    final categories = ['All', ...grouped.keys];

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Pull-to-refresh (iOS only — Android uses RefreshIndicator
                // which should wrap the CustomScrollView at a higher level).
                if (isIOS)
                  CupertinoSliverRefreshControl(
                    onRefresh: storeProvider.refreshData,
                  ),

                // Home header (greeting, location, etc.)
                const SliverToBoxAdapter(child: HomeHeader()),

                // "Restaurants" label
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
                      ),
                    ),
                  ),
                ),

                // Store selector row — fade + slide in on first render.
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

                // Sticky category selector.
                SliverPersistentHeader(
                  // Give it a unique key per store so it rebuilds when the
                  // store changes and the category list may differ.
                  key: ValueKey(_activeStoreId),
                  pinned: true,
                  delegate: CategoryHeaderDelegate(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: CategorySelector(
                      selectedCategory: _selectedCategory,
                      categories: categories,
                      onCategorySelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                ),

                // Menu items — fade in on category / store switch.
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 120),
                  sliver: AnimatedMenuList(
                    // key forces a fresh animation when the store changes.
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

            // Floating cart bar pinned above the bottom safe area.
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

  // ── Add-item flow ──────────────────────────────────────────────────────────

  /// Opens the options sheet for items that need configuration, or adds
  /// directly to the cart for simple items.
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

  // ── Dialog / snackbar helpers ──────────────────────────────────────────────

  void _showAddedSnackBar(BuildContext context, String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName added to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Prompts the user to clear their cart before adding an item from a
  /// different store. Adapts to the platform's native dialog style.
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
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
