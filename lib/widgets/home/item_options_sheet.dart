import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../utils/price_calculator.dart';
import '../../constants/static_data.dart';
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

class _ItemOptionsSheetState extends State<ItemOptionsSheet> {
  int _quantity = 1;
  String? _selectedSoupId;
  final Map<String, int> _selectedMeats = {'Small': 0, 'Big': 0};
  bool _hasSalad = false;
  final Map<String, int> _selectedAddons = {};

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();

    final availableSoups = widget.item.category == 'Swallow'
        ? storeProvider.menuItems
            .where((m) => m.category == 'Soup' && m.storeId == widget.item.storeId)
            .toList()
        : <MenuItem>[];

    final availableAddons = widget.item.addonIds != null
        ? widget.item.addonIds!
            .map((id) => storeProvider.menuItems.firstWhere((m) => m.id == id))
            .toList()
        : <MenuItem>[];

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
                      widget.item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ItemDetailOptionsSection(
                    title: 'Add Meat',
                    children: [
                      ItemDetailMeatOption(
                        type: 'Small',
                        price: StaticData.meatPrices['Small']!,
                        count: _selectedMeats['Small']!,
                        accentColor: widget.accentColor,
                        onChanged: (c) => setState(() => _selectedMeats['Small'] = c),
                      ),
                      ItemDetailMeatOption(
                        type: 'Big',
                        price: StaticData.meatPrices['Big']!,
                        count: _selectedMeats['Big']!,
                        accentColor: widget.accentColor,
                        onChanged: (c) => setState(() => _selectedMeats['Big'] = c),
                      ),
                    ],
                  ),
                  if (availableAddons.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ItemDetailOptionsSection(
                      title: 'Add-ons',
                      children: availableAddons
                          .map(
                            (addon) => ItemDetailAddonOption(
                              addon: addon,
                              count: _selectedAddons[addon.id] ?? 0,
                              accentColor: widget.accentColor,
                              onChanged: (c) => setState(() => _selectedAddons[addon.id] = c),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (widget.item.category == 'Rice' || widget.item.name == 'Moi Moi') ...[
                    const SizedBox(height: 24),
                    ItemDetailOptionsSection(
                      title: 'Extras',
                      children: [
                        ItemDetailSaladOption(
                          hasSalad: _hasSalad,
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
                              onTap: () => setState(() => _selectedSoupId = soup.id),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _quantityStepper(),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => _handleAddToCart(cartProvider, storeProvider),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Add to Cart • ₦${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
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

  void _handleAddToCart(CartProvider cartProvider, StoreProvider storeProvider) {
    if (widget.item.category == 'Swallow' && _selectedSoupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a soup first')),
      );
      return;
    }

    final success = cartProvider.addToCart(
      item: widget.item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      hasSalad: _hasSalad,
      selectedAddons: _selectedAddons,
    );

    if (success) {
      if (_selectedSoupId != null) {
        final soup = storeProvider.menuItems.firstWhere((m) => m.id == _selectedSoupId);
        cartProvider.addToCart(item: soup, quantity: _quantity);
      }
      Navigator.pop(context);
    } else {
      // Logic for different store would go here, 
      // but for simplicity in the sheet we can just show a message 
      // or let the HomeScreen handle the dialog.
      Navigator.pop(context, 'CLEAR_REQUIRED');
    }
  }
}
