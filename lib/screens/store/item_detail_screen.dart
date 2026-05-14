import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../utils/price_calculator.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';

import 'components/item_detail_scroll_body.dart';
import 'components/item_detail_footer.dart';
import 'components/item_detail_dialogs.dart';

class ItemDetailScreen extends StatefulWidget {
  final String id;

  const ItemDetailScreen({super.key, required this.id});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────

  int _quantity = 1;
  String? _selectedSoupId;
  final Map<String, int> _selectedMeats = {'Small': 0, 'Big': 0};
  bool _hasSalad = false;
  final Map<String, int> _selectedAddons = {};
  StreamSubscription<String>? _alertSub;

  // ── Animation controllers ──────────────────────────────────────────────────

  late final AnimationController _heroController;
  late final AnimationController _contentController;
  late final AnimationController _footerController;

  late final Animation<double> _heroScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<Offset> _footerSlide;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupAlertListener();
  }

  void _setupAnimations() {
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
    _footerSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _footerController, curve: Curves.easeOutBack),
    );

    // Staggered entrance
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 180), _contentController.forward);
    Future.delayed(const Duration(milliseconds: 320), _footerController.forward);
  }

  void _setupAlertListener() {
    // context.read is safe in initState — the widget is already in the tree
    // and providers are mounted above it. Never use context.watch here.
    _alertSub = context.read<StoreProvider>().alertStream.listen((alert) {
      if (alert == 'ITEM_UNAVAILABLE:${widget.id}') {
        _showUnavailableDialog();
      }
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _heroController.dispose();
    _contentController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── Resolve item safely ────────────────────────────────────────────────
    // menuItems may still be loading; show a spinner rather than throwing.
    final item = storeProvider.menuItems.cast<MenuItem?>().firstWhere(
      (m) => m?.id == widget.id,
      orElse: () => null,
    );

    if (item == null) {
      return Scaffold(
        body: Center(
          child: storeProvider.isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Item not found', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
        ),
      );
    }

    final store = storeProvider.stores.cast<dynamic>().firstWhere(
      (s) => s.id == item.storeId,
      orElse: () => storeProvider.stores.isNotEmpty ? storeProvider.stores.first : null,
    );

    if (store == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Store not found'),
              TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    final availableSoups = item.category == 'Swallow'
        ? storeProvider.menuItems
            .where((m) => m.category == 'Soup')
            .toList()
        : <MenuItem>[];

    // Filter addon IDs — skip any that haven't loaded yet
    final availableAddons = (item.addonIds ?? [])
        .map((id) => storeProvider.menuItems.cast<MenuItem?>().firstWhere(
              (m) => m?.id == id,
              orElse: () => null,
            ))
        .whereType<MenuItem>()
        .toList();

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
              accentColor: store.accentColor,
              availableSoups: availableSoups,
              availableAddons: availableAddons,
              selectedMeats: _selectedMeats,
              selectedAddons: _selectedAddons,
              hasSalad: _hasSalad,
              selectedSoupId: _selectedSoupId,
              meatPrices: storeProvider.meatPrices,
              saladPrice: storeProvider.saladPrice,
              isDark: isDark,
              onMeatChanged: (type, count) =>
                  setState(() => _selectedMeats[type] = count),
              onAddonChanged: (id, count) =>
                  setState(() => _selectedAddons[id] = count),
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
                  accentColor: store.accentColor,
                  isDark: isDark,
                  selectedSoupId: _selectedSoupId,
                  selectedMeats: _selectedMeats,
                  hasSalad: _hasSalad,
                  selectedAddons: _selectedAddons,
                  availableSoups: availableSoups,
                  cartProvider: cartProvider,
                  onQuantityChanged: (q) => setState(() => _quantity = q),
                  onAddToCart: () => _handleAddToCart(
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

  // ── Cart logic ─────────────────────────────────────────────────────────────

  void _handleAddToCart(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    StoreProvider storeProvider,
  ) {
    // Guard: soup required for this swallow
    if (item.requiresSoupSelection && _selectedSoupId == null) {
      _showSnack(context, 'Please select a soup first');
      return;
    }

    // Build the selectedSoup payload if a soup was chosen
    Map<String, dynamic>? soupPayload;
    if (_selectedSoupId != null) {
      final soup = storeProvider.menuItems.cast<MenuItem?>().firstWhere(
        (m) => m?.id == _selectedSoupId,
        orElse: () => null,
      );
      if (soup != null) {
        soupPayload = {
          'id': soup.id,
          'name': soup.name,
          // If isFreeWithSwallow the customer pays ₦0 for the soup
          'price': soup.isFreeWithSwallow ? 0.0 : soup.price,
        };
      }
    }

    final success = cartProvider.addToCart(
      item: item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      hasSalad: _hasSalad,
      selectedAddons: _selectedAddons,
      selectedSoup: soupPayload,
    );

    if (success) {
      context.pop();
    } else {
      _showClearCartDialog(context, cartProvider, item, storeProvider, soupPayload);
    }
  }

  // ── Dialogs & snackbars ────────────────────────────────────────────────────

  void _showUnavailableDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Item Unavailable',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'We apologize, but this item has just become unavailable. '
          'You will be returned to the store menu.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    StoreProvider storeProvider,
    Map<String, dynamic>? soupPayload,
  ) {
    showDialog(
      context: context,
      builder: (_) => ItemDetailClearCartDialog(
        onConfirm: () {
          cartProvider.forceClearAndAdd(
            item: item,
            quantity: _quantity,
            selectedMeats: _selectedMeats,
            hasSalad: _hasSalad,
            selectedAddons: _selectedAddons,
            selectedSoup: soupPayload,
          );
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
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
}