import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:campuschow/store/pages/features/orders/presentation/cart_provider.dart';
import 'package:campuschow/store/pages/features/store/data/menu_item_model.dart';
import 'package:campuschow/store/pages/features/store/presentation/store_provider.dart';

import 'widgets/item_detail_scroll_body.dart';
import 'widgets/item_detail_footer.dart';
import 'widgets/item_detail_dialogs.dart';

// ─────────────────────────────────────────────
//  Entry point
// ─────────────────────────────────────────────

class ItemDetailScreen extends StatefulWidget {
  final String id;

  const ItemDetailScreen({super.key, required this.id});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────
  int _quantity = 1;
  String? _selectedSoupId;
  final Map<String, int> _selectedMeats = {};
  final Map<String, int> _selectedSides = {};
  final Map<String, int> _selectedDrinks = {};
  final Map<String, int> _selectedAddons = {};

  // ── Animation controllers ──────────────────
  late final AnimationController _heroController;
  late final AnimationController _contentController;
  late final AnimationController _footerController;

  late final Animation<double> _heroScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<Offset> _footerSlide;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _heroScale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
          ),
        );
    _footerSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _footerController, curve: Curves.easeOutBack),
        );

    // Staggered entrance
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _footerController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  // ── Derived data ───────────────────────────

  double _computeTotal({
    required MenuItem item,
    required List<MenuItem> availableSoups,
    required List<MenuItem> availableAddons,
    required List<MenuItem> availableMeats,
    required List<MenuItem> availableSalads,
    required Map<String, double> meatPrices,
    required double saladPrice,
  }) {
    var total = item.price;
    _selectedMeats.forEach((id, count) {
      final meat = availableMeats.where((m) => m.id == id).firstOrNull;
      if (meat != null) {
        total += meat.price * count;
      } else {
        total += (meatPrices[id] ?? 0) * count;
      }
    });
    _selectedSides.forEach((id, count) {
      final side = availableSalads.where((m) => m.id == id).firstOrNull;
      if (side != null) {
        total += side.price * count;
      } else {
        total += saladPrice * count;
      }
    });
    _selectedDrinks.forEach((id, count) {
      final drink = availableSalads.where((m) => m.id == id).firstOrNull;
      if (drink != null) total += drink.price * count;
    });
    if (_selectedSoupId != null) {
      try {
        final soup = availableSoups.firstWhere((s) => s.id == _selectedSoupId);
        if (!soup.isFreeWithSwallow) total += soup.price;
      } catch (_) {}
    }
    _selectedAddons.forEach((id, count) {
      try {
        final addon = availableAddons.firstWhere((m) => m.id == id);
        total += addon.price * count;
      } catch (_) {}
    });
    return total * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    MenuItem? item;
    try {
      item = storeProvider.menuItems.firstWhere((m) => m.id == widget.id);
    } catch (_) {
      return const Scaffold(body: Center(child: Text('Item not found')));
    }

    final store = storeProvider.activeStore;
    if (store == null) {
      return const Scaffold(body: Center(child: Text('Store not found')));
    }
    final accentColor = store.color;

    final availableSoups = item.type == 'swallow' || item.compatibleWith?.contains('soup') == true
        ? storeProvider.menuItems
              .where((m) => m.type == 'soup')
              .toList()
        : <MenuItem>[];

    final availableAddons = item.addonIds != null
        ? item.addonIds!
              .map(
                (id) {
                  try {
                    return storeProvider.menuItems.firstWhere((m) => m.id == id);
                  } catch (_) {
                    return null;
                  }
                },
              )
              .whereType<MenuItem>()
              .toList()
        : <MenuItem>[];

    final availableMeats = storeProvider.meatItems;
    final availableSalads = storeProvider.saladItems;

    final totalPrice = _computeTotal(
      item: item,
      availableSoups: availableSoups,
      availableAddons: availableAddons,
      availableMeats: availableMeats,
      availableSalads: availableSalads,
      meatPrices: storeProvider.meatPrices,
      saladPrice: storeProvider.saladPrice,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            ItemDetailScrollBody(
              heroController: _heroController,
              heroScale: _heroScale,
              contentFade: _contentFade,
              contentSlide: _contentSlide,
              item: item,
              store: store,
              accentColor: accentColor,
              availableSoups: availableSoups,
              availableAddons: availableAddons,
              availableMeats: availableMeats,
              availableSalads: availableSalads,
              selectedMeats: _selectedMeats,
              selectedSides: _selectedSides,
              selectedDrinks: _selectedDrinks,
              selectedAddons: _selectedAddons,
              selectedSoupId: _selectedSoupId,
              isDark: isDark,
              onMeatChanged: (id, count) =>
                  setState(() => _selectedMeats[id] = count),
              onSideChanged: (id, count) =>
                  setState(() => _selectedSides[id] = count),
              onDrinkChanged: (id, count) =>
                  setState(() => _selectedDrinks[id] = count),
              onAddonChanged: (id, count) =>
                  setState(() => _selectedAddons[id] = count),
              onSoupSelected: (id) => setState(() => _selectedSoupId = id),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _footerSlide,
                child: ItemDetailFooter(
                  item: item,
                  quantity: _quantity,
                  totalPrice: totalPrice,
                  accentColor: accentColor,
                  isDark: isDark,
                  selectedSoupId: _selectedSoupId,
                  selectedMeats: _selectedMeats,
                  selectedSides: _selectedSides,
                  selectedDrinks: _selectedDrinks,
                  selectedAddons: _selectedAddons,
                  availableSoups: availableSoups,
                  cartProvider: cartProvider,
                  onQuantityChanged: (q) => setState(() => _quantity = q),
                  onAddToCart: () => _handleAddToCart(
                    context,
                    cartProvider,
                    item!,
                    storeProvider,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddToCart(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    StoreProvider storeProvider,
  ) {
    if ((item.type == 'swallow' || item.compatibleWith?.contains('soup') == true) && _selectedSoupId == null) {
      _showSnack(context, 'Please select a soup first');
      return;
    }

    final success = cartProvider.addToCart(
      item: item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      selectedSides: _selectedSides,
      selectedDrinks: _selectedDrinks,
      selectedAddons: _selectedAddons,
    );

    if (success) {
      _addSoupIfNeeded(cartProvider, storeProvider);
      context.pop();
    } else {
      _showClearCartDialog(context, cartProvider, item, storeProvider);
    }
  }

  void _addSoupIfNeeded(
    CartProvider cartProvider,
    StoreProvider storeProvider,
  ) {
    if (_selectedSoupId == null) return;
    try {
      final soup = storeProvider.menuItems.firstWhere(
        (m) => m.id == _selectedSoupId,
      );
      cartProvider.addToCart(item: soup, quantity: _quantity);
    } catch (_) {
      // Could not find soup
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showClearCartDialog(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    StoreProvider storeProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => ClearCartDialog(
        onConfirm: () {
          cartProvider.forceClearAndAdd(
            item: item,
            quantity: _quantity,
            selectedMeats: _selectedMeats,
            selectedSides: _selectedSides,
            selectedDrinks: _selectedDrinks,
            selectedAddons: _selectedAddons,
          );
          _addSoupIfNeeded(cartProvider, storeProvider);
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
  }
}
