import 'dart:async';
import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import 'components/store_detail_app_bar.dart';
import 'components/store_detail_closed_widgets.dart';
import 'components/store_detail_header.dart';
import 'components/store_detail_menu.dart';

import 'package:campuschow/widgets/responsive_layout.dart';

const _kCategories = <String>[
  'Rice & Pasta',
  'Swallow & Soup',
  'Drinks',
  'Side',
  'Protein',
  'Snacks & Pastries',
  'Others',
];

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
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
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();

    final store = storeProvider.stores.firstWhere((s) => s.id == widget.id);

    final groupedItems = _groupByCategory(
      storeProvider.menuItems
          .where((m) => m.storeId == widget.id && m.type != 'soup')
          .toList(),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── AppColors palette ─────────────────────────────────────────────
    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final chipBgColor = isDark
        ? AppColors.darkSurface2
        : AppColors.lightSurface;
    final statBgColor = chipBgColor; // identical background for stat badges
    final errorColor = isDark ? Colors.red.shade300 : Colors.red;

    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                StoreAppBar(
                  store: store,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  errorColor: errorColor,
                  isDark: isDark,
                ),

                SliverToBoxAdapter(
                  child: StoreHeader(
                    store: store,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    borderColor: borderColor,
                    statBgColor: statBgColor,
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: CategoryHeaderDelegate(
                    categories: groupedItems.keys.toList(),
                    onCategoryTap: _scrollToCategory,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    chipBgColor: chipBgColor,
                    borderColor: borderColor,
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
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      chipBgColor: chipBgColor,
                      borderColor: borderColor,
                    );
                  }, childCount: groupedItems.length),
                ),

                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox(height: 80.h),
                ),
              ],
            ),

            if (!store.isOpen) const StoreClosedBanner(),
          ],
        ),
      ),
    );
  }

  Map<String, List<MenuItem>> _groupByCategory(List<MenuItem> items) {
    final result = <String, List<MenuItem>>{};
    for (final category in _kCategories) {
      final matches = items.where((i) => i.category == category).toList();
      if (matches.isNotEmpty) result[category] = matches;
    }
    return result;
  }
}
