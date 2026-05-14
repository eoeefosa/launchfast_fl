import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../utils/price_calculator.dart';
import '../../screens/store/components/item_detail_options.dart';

class ItemOptionsSheet extends StatefulWidget {
  final MenuItem item;
  final Color accentColor;

  const ItemOptionsSheet({
    super.key,
    required this.item,
    required this.accentColor,
  });

  @override
  State<ItemOptionsSheet> createState() => _ItemOptionsSheetState();
}

enum CustomizerStep { portions, addons }

class _ItemOptionsSheetState extends State<ItemOptionsSheet> {
  CustomizerStep _currentStep = CustomizerStep.portions;
  int _quantity = 1;
  String? _selectedSoupId;
  final Map<String, int> _selectedMeats = {'Small': 0, 'Big': 0};
  bool _hasSalad = false;
  String? _selectedSizeId;
  final Map<String, int> _selectedAddons = {};

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();

    final availableSoups = widget.item.category == 'Swallow'
        ? storeProvider.menuItems
              .where(
                (m) => m.category == 'Soup',
              )
              .toList()
        : <MenuItem>[];

    final availableAddons = <MenuItem>[];
    
    // 1. Addons explicitly defined by ID
    if (widget.item.addonIds != null) {
      availableAddons.addAll(
        widget.item.addonIds!
            .map((id) => storeProvider.menuItems.firstWhereOrNull((m) => m.id == id))
            .whereType<MenuItem>(),
      );
    }

    // 2. Dynamic addons for Rice based on categories
    if (widget.item.category == 'Rice') {
      final riceAddonCategories = ['Meat', 'Fish', 'Chicken', 'Eggs', 'Salad', 'Drinks', 'Water'];
      final dynamicAddons = storeProvider.menuItems.where((m) {
        // Only include if it's in the specified categories AND not already in the list
        return riceAddonCategories.contains(m.category) && 
               !availableAddons.any((existing) => existing.id == m.id);
      });
      availableAddons.addAll(dynamicAddons);
    }

    final totalPrice = PriceCalculator.computeTotal(
      item: widget.item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      hasSalad: _hasSalad,
      selectedAddons: _selectedAddons,
      selectedSoupId: _selectedSoupId,
      availableSoups: availableSoups,
      availableAddons: availableAddons,
      meatPrices: storeProvider.meatPrices,
      saladPrice: storeProvider.saladPrice,
      selectedSizeId: _selectedSizeId,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _currentStep == CustomizerStep.portions 
                        ? 'Step 1: Select Portions' 
                        : 'Step 2: Add Complements',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == CustomizerStep.portions 
                  ? _buildPortionsStep()
                  : _buildAddonsStep(storeProvider, availableSoups, availableAddons),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_currentStep == CustomizerStep.addons) ...[
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep = CustomizerStep.portions),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_currentStep == CustomizerStep.portions) {
                      setState(() => _currentStep = CustomizerStep.addons);
                    } else {
                      _handleAddToCart(cartProvider, storeProvider);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentStep == CustomizerStep.portions
                      ? 'Next: Add Complements'
                      : 'Add to Cart • ₦${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortionsStep() {
    return Column(
      key: const ValueKey('portions'),
      children: [
        const SizedBox(height: 20),
        Text(
          'How many portions of ${widget.item.name}?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _quantityStepperLarge(),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAddonsStep(StoreProvider storeProvider, List<MenuItem> availableSoups, List<MenuItem> availableAddons) {
    return Column(
      key: const ValueKey('addons'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.item.sizes.isNotEmpty) ...[
          RadioGroup<String>(
            groupValue:
                _selectedSizeId ??
                (widget.item.sizes.isNotEmpty
                    ? widget.item.sizes.first.id
                    : null),
            onChanged: (val) => setState(() => _selectedSizeId = val),
            child: ItemDetailOptionsSection(
              title: 'Select Size',
              subtitle: 'Required',
              children:
                  widget.item.sizes.map((size) {
                    return ListTile(
                      title: Text(size.name),
                      trailing: Text(
                        '₦${size.price.toStringAsFixed(0)}',
                      ),
                      leading: Radio<String>(
                        value: size.id,
                        activeColor: widget.accentColor,
                      ),
                      onTap:
                          () => setState(
                            () => _selectedSizeId = size.id,
                          ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
        ItemDetailOptionsSection(
          title: 'Add Meat',
          children: [
            ItemDetailMeatOption(
              type: 'Small',
              price: storeProvider.meatPrices['Small']!,
              count: _selectedMeats['Small']!,
              accentColor: widget.accentColor,
              onChanged: (c) =>
                  setState(() => _selectedMeats['Small'] = c),
            ),
            ItemDetailMeatOption(
              type: 'Big',
              price: storeProvider.meatPrices['Big']!,
              count: _selectedMeats['Big']!,
              accentColor: widget.accentColor,
              onChanged: (c) =>
                  setState(() => _selectedMeats['Big'] = c),
            ),
          ],
        ),
        if (availableAddons.isNotEmpty) ...[
          const SizedBox(height: 24),
          ItemDetailOptionsSection(
            title: 'Add-ons (Sides & Drinks)',
            children: availableAddons
                .map(
                  (addon) => ItemDetailAddonOption(
                    addon: addon,
                    count: _selectedAddons[addon.id] ?? 0,
                    accentColor: widget.accentColor,
                    onChanged: (c) =>
                        setState(() => _selectedAddons[addon.id] = c),
                  ),
                )
                .toList(),
          ),
        ],
        if (widget.item.category == 'Rice' ||
            widget.item.name == 'Moi Moi') ...[
          const SizedBox(height: 24),
          ItemDetailOptionsSection(
            title: 'Extras',
            children: [
              ItemDetailSaladOption(
                hasSalad: _hasSalad,
                price: storeProvider.saladPrice,
                accentColor: widget.accentColor,
                onChanged: (val) => setState(() => _hasSalad = val),
              ),
            ],
          ),
        ],
        if (widget.item.category == 'Swallow') ...[
          const SizedBox(height: 24),
          ItemDetailOptionsSection(
            title: 'Choose a Soup',
            subtitle: 'Required',
            children: availableSoups
                .map(
                  (soup) => ItemDetailSoupOption(
                    soup: soup,
                    isSelected: _selectedSoupId == soup.id,
                    accentColor: widget.accentColor,
                    onTap: () =>
                        setState(() => _selectedSoupId = soup.id),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _quantityStepperLarge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove_rounded, size: 32),
            padding: const EdgeInsets.all(16),
          ),
          const SizedBox(width: 20),
          Text(
            '$_quantity',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 36),
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add_rounded, size: 32),
            padding: const EdgeInsets.all(16),
          ),
        ],
      ),
    );
  }

  Widget _quantityStepper() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text(
            '$_quantity',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  void _handleAddToCart(
    CartProvider cartProvider,
    StoreProvider storeProvider,
  ) {
    if (widget.item.category == 'Swallow' && _selectedSoupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a soup first')),
      );
      return;
    }

    // Build the selectedSoup payload if a soup was chosen
    Map<String, dynamic>? soupPayload;
    if (_selectedSoupId != null) {
      final soup = storeProvider.menuItems.firstWhere(
        (m) => m.id == _selectedSoupId,
      );
      soupPayload = {
        'id': soup.id,
        'name': soup.name,
        // If isFreeWithSwallow the customer pays ₦0 for the soup
        'price': soup.isFreeWithSwallow ? 0.0 : soup.price,
      };
    }

    final success = cartProvider.addToCart(
      item: widget.item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      hasSalad: _hasSalad,
      selectedAddons: _selectedAddons,
      selectedSoup: soupPayload,
    );

    if (success) {
      Navigator.pop(context);
    } else {
      // Logic for different store would go here,
      // but for simplicity in the sheet we can just show a message
      // or let the HomeScreen handle the dialog.
      Navigator.pop(context, 'CLEAR_REQUIRED');
    }
  }
}
