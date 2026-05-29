import 'dart:async';
import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../utils/price_calculator.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';

import 'components/item_detail_scroll_body.dart';
import 'components/item_detail_footer.dart';
import 'components/item_detail_dialogs.dart'; // keep for unavailable dialog
import 'components/item_detail_placeholders.dart';

import 'package:campuschow/widgets/responsive_layout.dart';

class ItemDetailScreen extends StatefulWidget {
  final String id;

  const ItemDetailScreen({super.key, required this.id});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with TickerProviderStateMixin {
  int _quantity = 1;
  String? _selectedSoupId;
  String? _selectedSizeId; // ← NEW: size selection
  final Map<String, int> _selectedMeats = {};
  final Map<String, int> _selectedSides = {};
  final Map<String, int> _selectedDrinks = {};
  final Map<String, int> _selectedAddons = {};
  StreamSubscription<String>? _alertSub;

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

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _footerController.forward();
    });
  }

  void _setupAlertListener() {
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

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;

    final item = storeProvider.menuItems.cast<MenuItem?>().firstWhere(
      (m) => m?.id == widget.id,
      orElse: () => null,
    );

    if (item == null) {
      return storeProvider.isLoading
          ? const ItemDetailLoadingView()
          : const ItemDetailErrorView(message: 'Item not found');
    }

    final store = storeProvider.stores.cast<dynamic>().firstWhere(
      (s) => s.id == item.storeId,
      orElse: () =>
          storeProvider.stores.isNotEmpty ? storeProvider.stores.first : null,
    );

    if (store == null) {
      return const ItemDetailErrorView(message: 'Store not found');
    }

    final components = _resolveAvailableComponents(item, storeProvider);

    // If sizes exist and no size is selected, auto-select the first one
    if (_selectedSizeId == null && item.sizes.isNotEmpty) {
      _selectedSizeId = item.sizes.first.id;
    }

    final totalPrice = PriceCalculator.computeTotal(
      item: item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      selectedSides: _selectedSides,
      selectedDrinks: _selectedDrinks,
      selectedAddons: _selectedAddons,
      selectedSoupId: _selectedSoupId,
      availableSoups: components.soups,
      availableAddons: components.addons,
      availableMeats: components.proteins,
      availableSides: components.sides,
      availableDrinks: components.drinks,
      meatPrices: storeProvider.meatPrices,
      saladPrice: storeProvider.saladPrice,
      selectedSizeId: _selectedSizeId, // ← pass size
    );

    final accentColor = store.accentColor;

    return ResponsiveLayout(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: scaffoldBg,
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
                availableSoups: components.soups,
                availableAddons: components.addons,
                availableProteins: components.proteins,
                availableSides: components.sides,
                availableDrinks: components.drinks,
                selectedMeats: _selectedMeats,
                selectedAddons: _selectedAddons,
                selectedSides: _selectedSides,
                selectedDrinks: _selectedDrinks,
                selectedSoupId: _selectedSoupId,
                selectedSizeId: _selectedSizeId, // ← NEW
                isDark: isDark,
                onMeatChanged: (id, count) =>
                    setState(() => _selectedMeats[id] = count),
                onAddonChanged: (id, count) =>
                    setState(() => _selectedAddons[id] = count),
                onSideChanged: (id, count) =>
                    setState(() => _selectedSides[id] = count),
                onDrinkChanged: (id, count) =>
                    setState(() => _selectedDrinks[id] = count),
                onSoupSelected: (id) => setState(() => _selectedSoupId = id),
                onSizeSelected: (id) =>
                    setState(() => _selectedSizeId = id), // ← NEW
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
                    selectedSizeId: _selectedSizeId, // ← NEW
                    selectedMeats: _selectedMeats,
                    selectedSides: _selectedSides,
                    selectedDrinks: _selectedDrinks,
                    selectedAddons: _selectedAddons,
                    availableSoups: components.soups,
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
      ),
    );
  }

  AvailableComponents _resolveAvailableComponents(
    MenuItem item,
    StoreProvider storeProvider,
  ) {
    final compatible = item.compatibleWith ?? [];

    final soups = compatible.contains('soup') || item.type == 'swallow'
        ? storeProvider.menuItems.where((m) => m.type == 'soup').toList()
        : <MenuItem>[];

    final proteins = compatible.contains('protein')
        ? storeProvider.menuItems
              .where((m) => m.storeId == item.storeId && m.type == 'protein')
              .toList()
        : <MenuItem>[];

    final sides = compatible.contains('side')
        ? storeProvider.menuItems
              .where((m) => m.storeId == item.storeId && m.type == 'side')
              .toList()
        : <MenuItem>[];

    final drinks = compatible.contains('drink')
        ? storeProvider.menuItems
              .where((m) => m.storeId == item.storeId && m.type == 'drink')
              .toList()
        : <MenuItem>[];

    final addons = (item.addonIds ?? [])
        .map(
          (id) => storeProvider.menuItems.cast<MenuItem?>().firstWhere(
            (m) => m?.id == id,
            orElse: () => null,
          ),
        )
        .whereType<MenuItem>()
        .toList();

    return AvailableComponents(
      soups: soups,
      proteins: proteins,
      sides: sides,
      drinks: drinks,
      addons: addons,
    );
  }

  void _handleAddToCart(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    StoreProvider storeProvider,
  ) {
    if ((item.category == 'Swallow' || item.requiresSoupSelection) &&
        _selectedSoupId == null) {
      _showSnack(context, 'Please select a soup first');
      return;
    }

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
          'price': soup.isFreeWithSwallow ? 0.0 : soup.price,
        };
      }
    }

    final success = cartProvider.addToCart(
      item: item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      selectedSides: _selectedSides,
      selectedDrinks: _selectedDrinks,
      selectedAddons: _selectedAddons,
      selectedSoup: soupPayload,
      selectedSizeId: _selectedSizeId, // ← include size
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} added to cart'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
      context.pop();
    } else {
      _showClearCartDialog(
        context,
        cartProvider,
        item,
        storeProvider,
        soupPayload,
      );
    }
  }

  void _showUnavailableDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ItemUnavailableDialog(),
    ).then((_) {
      if (mounted) context.pop();
    });
  }

  // ── Premium clear‑cart dialog (styled like the sheet) ───────────────────
  void _showClearCartDialog(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    StoreProvider storeProvider,
    Map<String, dynamic>? soupPayload,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextSecondary : AppColors.lightMuted;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          'Start a new order?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17.sp,
            color: text,
          ),
        ),
        content: Text(
          'Your cart has items from another store. Clear it and add this item?',
          style: TextStyle(color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: muted)),
          ),
          TextButton(
            onPressed: () {
              cartProvider.forceClearAndAdd(
                item: item,
                quantity: _quantity,
                selectedMeats: _selectedMeats,
                selectedSides: _selectedSides,
                selectedDrinks: _selectedDrinks,
                selectedAddons: _selectedAddons,
                selectedSoup: soupPayload,
                selectedSizeId: _selectedSizeId, // ← include size
              );
              Navigator.pop(context); // close dialog
              context.pop(); // close screen
            },
            child: Text(
              'Clear & Add',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}

class AvailableComponents {
  final List<MenuItem> soups;
  final List<MenuItem> proteins;
  final List<MenuItem> sides;
  final List<MenuItem> drinks;
  final List<MenuItem> addons;

  AvailableComponents({
    required this.soups,
    required this.proteins,
    required this.sides,
    required this.drinks,
    required this.addons,
  });
}
