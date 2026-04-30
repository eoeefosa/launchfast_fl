import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../utils/price_calculator.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';
import '../../constants/static_data.dart';

import 'components/item_detail_scroll_body.dart';
import 'components/item_detail_footer.dart';
import 'components/item_detail_dialogs.dart';

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
  final Map<String, int> _selectedMeats = {'Small': 0, 'Big': 0};
  bool _hasSalad = false;
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
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _footerSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _footerController, curve: Curves.easeOutBack),
        );

    // Staggered entrance
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 180), _contentController.forward);
    Future.delayed(const Duration(milliseconds: 320), _footerController.forward);
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  // ── Derived data ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final item = storeProvider.menuItems.firstWhere((m) => m.id == widget.id);
    final store = storeProvider.stores.firstWhere(
      (s) => s.id == item.storeId,
      orElse: () => storeProvider.stores.first,
    );
    final accentColor = store.accentColor;

    final availableSoups =
        item.category == 'Swallow'
            ? storeProvider.menuItems
                .where((m) => m.category == 'Soup' && m.storeId == item.storeId)
                .toList()
            : <MenuItem>[];

    final availableAddons =
        item.addonIds != null
            ? item.addonIds!
                .map((id) => storeProvider.menuItems.firstWhere((m) => m.id == id))
                .toList()
            : <MenuItem>[];

    final totalPrice = PriceCalculator.computeTotal(
      item: item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      hasSalad: _hasSalad,
      selectedAddons: _selectedAddons,
      selectedSoupId: _selectedSoupId,
      availableSoups: availableSoups,
      availableAddons: availableAddons,
      meatPrices: storeProvider.meatPrices,
      saladPrice: storeProvider.saladPrice,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
              selectedMeats: _selectedMeats,
              selectedAddons: _selectedAddons,
              hasSalad: _hasSalad,
              selectedSoupId: _selectedSoupId,
              isDark: isDark,
              onMeatChanged:
                  (type, count) => setState(() => _selectedMeats[type] = count),
              onAddonChanged:
                  (id, count) => setState(() => _selectedAddons[id] = count),
              onSaladChanged: (val) => setState(() => _hasSalad = val),
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
                  hasSalad: _hasSalad,
                  selectedAddons: _selectedAddons,
                  availableSoups: availableSoups,
                  cartProvider: cartProvider,
                  onQuantityChanged: (q) => setState(() => _quantity = q),
                  onAddToCart:
                      () => _handleAddToCart(
                        context,
                        cartProvider,
                        item,
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
    if (item.category == 'Swallow' && _selectedSoupId == null) {
      _showSnack(context, 'Please select a soup first');
      return;
    }

    final success = cartProvider.addToCart(
      item: item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      hasSalad: _hasSalad,
      selectedAddons: _selectedAddons,
    );

    if (success) {
      _addSoupIfNeeded(cartProvider, storeProvider);
      context.pop();
    } else {
      _showClearCartDialog(context, cartProvider, item, storeProvider);
    }
  }

  void _addSoupIfNeeded(CartProvider cartProvider, StoreProvider storeProvider) {
    if (_selectedSoupId == null) return;
    final soup = storeProvider.menuItems.firstWhere(
      (m) => m.id == _selectedSoupId,
    );
    cartProvider.addToCart(item: soup, quantity: _quantity);
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
      builder:
          (_) => ItemDetailClearCartDialog(
            onConfirm: () {
              cartProvider.forceClearAndAdd(
                item: item,
                quantity: _quantity,
                selectedMeats: _selectedMeats,
                hasSalad: _hasSalad,
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
