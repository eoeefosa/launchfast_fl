import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/features/orders/presentation/cart_provider.dart';
import 'widgets/item_detail_header.dart';
import 'widgets/item_hero_image.dart';
import 'widgets/item_option_widgets.dart';
import 'widgets/stepper_control.dart';

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
  final Map<String, int> _selectedMeats = {};
  final Map<String, int> _selectedSides = {};
  final Map<String, int> _selectedDrinks = {};
  final Map<String, int> _selectedAddons = {};
  StreamSubscription? _alertSub;

  late final AnimationController _heroController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _heroScale = Tween<double>(begin: 1.08, end: 1.0)
      .animate(
        CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
      );

  @override
  void initState() {
    super.initState();
    _heroController.forward();
    _setupAlertListener();
  }

  void _setupAlertListener() {
    final provider = context.read<StoreProvider>();
    _alertSub = provider.alertStream.listen((alert) {
      if (alert == 'ITEM_UNAVAILABLE:${widget.id}') {
        _showUnavailableDialog();
      }
    });
  }

  void _showUnavailableDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Item Unavailable', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'This item has just been marked as unavailable.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Pop dialog
              context.pop(); // Pop screen
            },
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  double _computeTotal(
    MenuItem item,
    List<MenuItem> soups,
    List<MenuItem> addons,
    List<MenuItem> availableMeats,
    List<MenuItem> availableSalads,
    Map<String, double> meatPrices,
    double saladPrice,
  ) {
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
      final soup = soups.where((s) => s.id == _selectedSoupId).firstOrNull;
      if (soup != null && !soup.isFreeWithSwallow) total += soup.price;
    }
    _selectedAddons.forEach((id, count) {
      final addon = addons.where((m) => m.id == id).firstOrNull;
      if (addon != null) total += addon.price * count;
    });
    return total * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final item = storeProvider.menuItems
        .where((m) => m.id == widget.id)
        .firstOrNull;
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Item not found')));
    }

    final store = storeProvider.activeStore;
    if (store == null) {
      return const Scaffold(body: Center(child: Text('Store not found')));
    }

    final soups = item.category == 'Swallow'
        ? storeProvider.menuItems
              .where((m) => m.category == 'Soup')
              .toList()
        : <MenuItem>[];
    final addons = (item.addonIds ?? [])
        .map(
          (id) => storeProvider.menuItems.where((m) => m.id == id).firstOrNull,
        )
        .whereType<MenuItem>()
        .toList();

    final availableMeats = storeProvider.meatItems;
    final availableSalads = storeProvider.saladItems;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                ItemHeroImage(imageUrl: item.image, heroScale: _heroScale),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ItemDetailHeader(
                        item: item,
                        storeName: store.name,
                        accentColor: store.color,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                      const SizedBox(height: 32),
                      _buildOptions(item, soups, addons, availableMeats, availableSalads, store.color),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(
            item, 
            _computeTotal(
              item, 
              soups, 
              addons, 
              availableMeats, 
              availableSalads, 
              storeProvider.meatPrices, 
              storeProvider.saladPrice
            ), 
            store.color
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(
    MenuItem item,
    List<MenuItem> soups,
    List<MenuItem> addons,
    List<MenuItem> availableMeats,
    List<MenuItem> availableSalads,
    Color accent,
  ) {
    return Column(
      children: [
        if (availableMeats.isNotEmpty)
          OptionSection(
            title: 'Add Meat',
            children: availableMeats.map((meat) => ItemOptionTile(
              item: meat,
              count: _selectedMeats[meat.id] ?? 0,
              accent: accent,
              onChanged: (c) => setState(() => _selectedMeats[meat.id] = c),
            )).toList(),
          ),
        if (availableSalads.isNotEmpty) ...[
          const SizedBox(height: 32),
          OptionSection(
            title: 'Add Sides',
            children: availableSalads.map((side) => ItemOptionTile(
              item: side,
              count: _selectedSides[side.id] ?? 0,
              accent: accent,
              onChanged: (c) => setState(() => _selectedSides[side.id] = c),
            )).toList(),
          ),
        ],
        if (soups.isNotEmpty) ...[
          const SizedBox(height: 32),
          OptionSection(
            title: 'Choose a Soup',
            subtitle: 'Required',
            children: [
              RadioGroup<String>(
                groupValue: _selectedSoupId,
                onChanged: (value) =>
                    setState(() => _selectedSoupId = value),
                child: Column(
                  children: soups
                      .map(
                        (s) => SelectionCard(
                          title: s.name,
                          subtitle: s.isFreeWithSwallow
                              ? 'Free'
                              : '₦${s.price}',
                          isSelected: _selectedSoupId == s.id,
                          onTap: () =>
                              setState(() => _selectedSoupId = s.id),
                          trailing: Radio<String>(value: s.id),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
        if (addons.isNotEmpty) ...[
          const SizedBox(height: 32),
          OptionSection(
            title: 'Add-ons',
            children: addons.map((addon) => ItemOptionTile(
              item: addon,
              count: _selectedAddons[addon.id] ?? 0,
              accent: accent,
              onChanged: (c) => setState(() => _selectedAddons[addon.id] = c),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(MenuItem item, double total, Color accent) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            StepperControl(
              count: _quantity,
              accentColor: accent,
              onDecrement: () =>
                  setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
              onIncrement: () => setState(() => _quantity++),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _addToCart(item),
                child: Text(
                  'Add to Cart • ₦${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(MenuItem item) {
    final cart = context.read<CartProvider>();
    final storeProvider = context.read<StoreProvider>();

    if (item.category == 'Swallow' && _selectedSoupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a soup')));
      return;
    }
    final success = cart.addToCart(
      item: item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      selectedSides: _selectedSides,
      selectedDrinks: _selectedDrinks,
      selectedAddons: _selectedAddons,
    );

    if (success && _selectedSoupId != null) {
      try {
        final soup = storeProvider.menuItems.firstWhere(
          (m) => m.id == _selectedSoupId,
        );
        cart.addToCart(item: soup, quantity: _quantity);
      } catch (_) {}
    }

    if (success) {
      context.pop();
    }
  }
}
