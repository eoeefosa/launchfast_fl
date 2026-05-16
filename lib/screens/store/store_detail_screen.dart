import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import 'components/store_detail_app_bar.dart';
import 'components/store_detail_closed_widgets.dart';
import 'components/store_detail_header.dart';
import 'components/store_detail_menu.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kCategories = <String>[
  'Rice',
  'Swallow',
  'Soup',
  'Drinks',
  'Extras',
  'Others',
];

// ─────────────────────────────────────────────────────────────────────────────
// StoreDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  // Owned resources — initialised in initState, disposed in dispose.
  late final ScrollController _scrollController;
  late final List<GlobalKey> _categoryKeys;
  StreamSubscription<String>? _alertSub;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _categoryKeys = List.generate(_kCategories.length, (_) => GlobalKey());
    _listenToAlerts();
  }

  /// Subscribes to the store-level alert stream.
  /// Uses [addPostFrameCallback] so [context] is safe to read.
  void _listenToAlerts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _alertSub = context.read<StoreProvider>().alertStream.listen(_onAlert);
    });
  }

  void _onAlert(String alert) {
    if (alert == 'STORE_CLOSED:${widget.id}') {
      _showClosedDialog();
    }
  }

  void _showClosedDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StoreClosedDialog(storeId: widget.id),
    );
  }

  void _scrollToCategory(int index) {
    final key = _categoryKeys[index];
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use watch only for data that should trigger a rebuild.
    final storeProvider = context.watch<StoreProvider>();
    // CartProvider is passed down — no rebuild needed at this level.
    final cartProvider = context.read<CartProvider>();

    final store = storeProvider.stores.firstWhere((s) => s.id == widget.id);

    final groupedItems = _groupByCategory(
      storeProvider.menuItems.where((m) => m.storeId == widget.id).toList(),
    );

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              StoreAppBar(store: store, scheme: scheme, isDark: isDark),
              SliverToBoxAdapter(
                child: StoreHeader(store: store, scheme: scheme),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: CategoryHeaderDelegate(
                  categories: groupedItems.keys.toList(),
                  onCategoryTap: _scrollToCategory,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = groupedItems.keys.elementAt(index);
                  final catItems = groupedItems[category]!;
                  return CategorySection(
                    category: category,
                    items: catItems,
                    categoryKey: _categoryKeys[index],
                    cartProvider: cartProvider,
                    accentColor: store.accentColor,
                    storeIsOpen: store.isOpen,
                    scheme: scheme,
                  );
                }, childCount: groupedItems.length),
              ),
              // Spacer at the bottom so content is not obscured by the banner.
              const SliverFillRemaining(
                hasScrollBody: false,
                child: SizedBox(height: 100),
              ),
            ],
          ),
          if (!store.isOpen) const StoreClosedBanner(),
        ],
      ),
    );
  }

  /// Groups [items] into an ordered map keyed by category name.
  Map<String, List<MenuItem>> _groupByCategory(List<MenuItem> items) {
    final result = <String, List<MenuItem>>{};
    for (final category in _kCategories) {
      final matches = items.where((i) => i.category == category).toList();
      if (matches.isNotEmpty) result[category] = matches;
    }
    return result;
  }
}
