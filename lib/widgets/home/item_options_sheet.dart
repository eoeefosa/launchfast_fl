import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _ItemOptionsSheetState extends State<ItemOptionsSheet> {
  int _quantity = 1;
  String? _selectedSoupId;
  final Map<String, int> _selectedMeats = {};
  final Map<String, int> _selectedSides = {};
  final Map<String, int> _selectedDrinks = {};
  String? _selectedSizeId;
  final Map<String, int> _selectedAddons = {};

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();

    final availableSoups = widget.item.type == 'swallow' || widget.item.compatibleWith?.contains('soup') == true
        ? storeProvider.menuItems
              .where(
                (m) => m.type == 'soup',
              )
              .toList()
        : <MenuItem>[];

    final availableProteins = storeProvider.menuItems
        .where((m) => m.storeId == widget.item.storeId && m.type == 'protein' && widget.item.compatibleWith?.contains('protein') == true)
        .toList();

    final availableSides = storeProvider.menuItems
        .where((m) => m.storeId == widget.item.storeId && m.type == 'side' && widget.item.compatibleWith?.contains('side') == true)
        .toList();

    final availableDrinks = storeProvider.menuItems
        .where((m) => m.storeId == widget.item.storeId && m.type == 'drink' && widget.item.compatibleWith?.contains('drink') == true)
        .toList();

    final availableAddons = widget.item.addonIds != null
        ? widget.item.addonIds!
              .map(
                (id) => storeProvider.menuItems.cast<MenuItem?>().firstWhere(
                      (m) => m?.id == id,
                      orElse: () => null,
                    ),
              )
              .whereType<MenuItem>()
              .toList()
        : <MenuItem>[];

    final totalPrice = PriceCalculator.computeTotal(
      item: widget.item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      selectedSides: _selectedSides,
      selectedDrinks: _selectedDrinks,
      selectedAddons: _selectedAddons,
      selectedSoupId: _selectedSoupId,
      availableSoups: availableSoups,
      availableAddons: availableAddons,
      availableMeats: availableProteins,
      availableSides: availableSides,
      availableDrinks: availableDrinks,
      meatPrices: storeProvider.meatPrices,
      saladPrice: storeProvider.saladPrice,
      selectedSizeId: _selectedSizeId,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
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
              child: Column(
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
                  if (availableProteins.isNotEmpty) ...[
                    ItemDetailOptionsSection(
                      title: 'Add Protein',
                      children: availableProteins
                          .map(
                            (meat) => ItemDetailQuantityOption(
                              item: meat,
                              count: _selectedMeats[meat.id] ?? 0,
                              accentColor: widget.accentColor,
                              onChanged: (c) =>
                                  setState(() => _selectedMeats[meat.id] = c),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (availableSides.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ItemDetailOptionsSection(
                      title: 'Add Sides',
                      children: availableSides
                          .map(
                            (side) => ItemDetailQuantityOption(
                              item: side,
                              count: _selectedSides[side.id] ?? 0,
                              accentColor: widget.accentColor,
                              onChanged: (c) =>
                                  setState(() => _selectedSides[side.id] = c),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (widget.item.type == 'swallow' || widget.item.compatibleWith?.contains('soup') == true) ...[
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
                  if (availableDrinks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ItemDetailOptionsSection(
                      title: 'Add Drinks',
                      children: availableDrinks
                          .map(
                            (drink) => ItemDetailQuantityOption(
                              item: drink,
                              count: _selectedDrinks[drink.id] ?? 0,
                              accentColor: widget.accentColor,
                              onChanged: (c) =>
                                  setState(() => _selectedDrinks[drink.id] = c),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (availableAddons.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ItemDetailOptionsSection(
                      title: 'Extras & Add-ons',
                      children: availableAddons
                          .map(
                            (addon) => ItemDetailQuantityOption(
                              item: addon,
                              count: _selectedAddons[addon.id] ?? 0,
                              accentColor: widget.accentColor,
                              onChanged: (c) =>
                                  setState(() => _selectedAddons[addon.id] = c),
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
                  onPressed: () =>
                      _handleAddToCart(cartProvider, storeProvider),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Add to Cart • ₦${totalPrice.toStringAsFixed(0)}',
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
    if (widget.item.type == 'swallow' && _selectedSoupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a soup first')),
      );
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
      item: widget.item,
      quantity: _quantity,
      selectedMeats: _selectedMeats,
      selectedSides: _selectedSides,
      selectedDrinks: _selectedDrinks,
      selectedAddons: _selectedAddons,
      selectedSoup: soupPayload,
      selectedSizeId: _selectedSizeId,
    );

    if (success) {
      Navigator.pop(context, 'SUCCESS');
    } else {
      // Handle cross-store cart clearing directly in the sheet to preserve options
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Start a new order?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: const Text('Your cart has items from another store. Clear it and add this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                cartProvider.forceClearAndAdd(
                  item: widget.item,
                  quantity: _quantity,
                  selectedMeats: _selectedMeats,
                  selectedSides: _selectedSides,
                  selectedDrinks: _selectedDrinks,
                  selectedAddons: _selectedAddons,
                  selectedSoup: soupPayload,
                  selectedSizeId: _selectedSizeId,
                );
                Navigator.pop(context); // close dialog
                Navigator.pop(context, 'SUCCESS'); // close sheet
              },
              child: const Text('Clear & Add', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }
  }
}
