import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';
import '../../constants/static_data.dart';

class ItemDetailScreen extends StatefulWidget {
  final String id;

  const ItemDetailScreen({super.key, required this.id});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _quantity = 1;
  String? _selectedSoupId;
  final Map<String, int> _selectedMeats = {'Small': 0, 'Big': 0};
  bool _hasSalad = false;
  final Map<String, int> _selectedAddons = {};

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();

    final item = storeProvider.menuItems.firstWhere((m) => m.id == widget.id);
    final store = StaticData.stores.firstWhere((s) => s.id == item.storeId);

    final availableSoups = item.category == 'Swallow'
        ? storeProvider.menuItems
              .where((m) => m.category == 'Soup' && m.storeId == item.storeId)
              .toList()
        : <MenuItem>[];

    final availableAddons = item.addonIds != null
        ? item.addonIds!
              .map(
                (id) => storeProvider.menuItems.firstWhere((m) => m.id == id),
              )
              .toList()
        : <MenuItem>[];

    double totalPrice = item.price;
    _selectedMeats.forEach((type, count) {
      totalPrice += (StaticData.meatPrices[type] ?? 0) * count;
    });
    if (_hasSalad) totalPrice += StaticData.saladPrice;
    if (_selectedSoupId != null) {
      final soup = availableSoups.firstWhere((s) => s.id == _selectedSoupId);
      if (!soup.isFreeWithSwallow) totalPrice += soup.price;
    }
    _selectedAddons.forEach((id, count) {
      final addon = availableAddons.firstWhere((m) => m.id == id);
      totalPrice += addon.price * count;
    });
    totalPrice *= _quantity;

    final accentColor = Color(
      int.parse(store.accentColor.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.image,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₦${item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                              if (item.isPerPortion)
                                Text(
                                  '/ portion',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'From ${store.name}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildOptionsSection('Add Meat', [
                        _buildMeatOption(
                          'Small',
                          StaticData.meatPrices['Small']!,
                        ),
                        _buildMeatOption('Big', StaticData.meatPrices['Big']!),
                      ]),
                      if (availableAddons.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildOptionsSection('Add-ons', [
                          ...availableAddons.map(
                            (addon) => _buildAddonOption(addon),
                          ),
                        ]),
                      ],
                      if (item.category == 'Rice' ||
                          item.name == 'Moi Moi') ...[
                        const SizedBox(height: 32),
                        _buildOptionsSection('Addons', [
                          _buildSaladOption(accentColor),
                        ]),
                      ],
                      if (item.category == 'Swallow') ...[
                        const SizedBox(height: 32),
                        _buildOptionsSection('Choose a Soup (Mandatory)', [
                          RadioGroup<String>(
                            groupValue: _selectedSoupId,
                            onChanged: (val) =>
                                setState(() => _selectedSoupId = val),
                            child: Column(
                              children: availableSoups
                                  .map((soup) => _buildSoupOption(soup, accentColor))
                                  .toList(),
                            ),
                          ),
                        ]),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFooter(
              context,
              cartProvider,
              item,
              totalPrice,
              accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildMeatOption(String type, double price) {
    final count = _selectedMeats[type] ?? 0;
    return _buildSelectionItem(
      title: '$type Meat',
      subtitle: '+₦${price.toStringAsFixed(2)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(
              () => _selectedMeats[type] = (count > 0 ? count - 1 : 0),
            ),
            icon: Icon(
              Icons.remove_circle_outline,
              color: Theme.of(
                context,
              ).primaryColor.withValues(alpha: count > 0 ? 1 : 0.3),
            ),
          ),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () => setState(() => _selectedMeats[type] = count + 1),
            icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonOption(MenuItem addon) {
    final count = _selectedAddons[addon.id] ?? 0;
    return _buildSelectionItem(
      title: addon.name,
      subtitle: '+₦${addon.price.toStringAsFixed(2)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(
              () => _selectedAddons[addon.id] = (count > 0 ? count - 1 : 0),
            ),
            icon: Icon(
              Icons.remove_circle_outline,
              color: Theme.of(
                context,
              ).primaryColor.withValues(alpha: count > 0 ? 1 : 0.3),
            ),
          ),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () =>
                setState(() => _selectedAddons[addon.id] = count + 1),
            icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSaladOption(Color accent) {
    return _buildSelectionItem(
      title: 'Fresh Salad',
      subtitle: '+₦${StaticData.saladPrice.toStringAsFixed(2)}',
      trailing: Checkbox(
        value: _hasSalad,
        activeColor: accent,
        onChanged: (val) => setState(() => _hasSalad = val ?? false),
      ),
    );
  }

  Widget _buildSoupOption(MenuItem soup, Color accent) {
    return _buildSelectionItem(
      title: soup.name,
      subtitle: soup.isFreeWithSwallow
          ? 'Free with swallow'
          : '₦${soup.price.toStringAsFixed(2)}',
      trailing: Radio<String>(
        value: soup.id,
        activeColor: accent,
      ),
      onTap: () => setState(() => _selectedSoupId = soup.id),
    );
  }

  Widget _buildSelectionItem({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500])),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    double totalPrice,
    Color accent,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => setState(
                  () => _quantity = (_quantity > 1 ? _quantity - 1 : 1),
                ),
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (item.category == 'Swallow' && _selectedSoupId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a soup')),
                  );
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
                  if (_selectedSoupId != null) {
                    final storeProvider = context.read<StoreProvider>();
                    final soup = storeProvider.menuItems.firstWhere(
                      (m) => m.id == _selectedSoupId,
                    );
                    cartProvider.addToCart(item: soup, quantity: _quantity);
                  }
                  context.pop();
                } else {
                  _showClearCartDialog(
                    context,
                    cartProvider,
                    item,
                    _selectedSoupId,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add to Cart',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '₦${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    String? soupId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start new order?'),
        content: const Text(
          'Your cart contains items from another store. Clear cart and add this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.forceClearAndAdd(
                item: item,
                quantity: _quantity,
                selectedMeats: _selectedMeats,
                hasSalad: _hasSalad,
                selectedAddons: _selectedAddons,
              );
              if (soupId != null) {
                final storeProvider = context.read<StoreProvider>();
                final soup = storeProvider.menuItems.firstWhere(
                  (m) => m.id == soupId,
                );
                cartProvider.addToCart(item: soup, quantity: _quantity);
              }
              Navigator.pop(context);
              context.pop();
            },
            child: const Text(
              'Clear & Add',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
