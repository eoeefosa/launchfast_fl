import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── AppColors accent ─────────────────────────────────────────────────
    final brandAccent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final dividerColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : AppColors.lightBorder.withValues(alpha: 0.4);

    // Data
    final availableSoups =
        (widget.item.type == 'swallow' ||
            widget.item.compatibleWith?.contains('soup') == true)
        ? storeProvider.menuItems.where((m) => m.type == 'soup').toList()
        : <MenuItem>[];

    final availableProteins = storeProvider.menuItems
        .where(
          (m) =>
              m.storeId == widget.item.storeId &&
              m.type == 'protein' &&
              widget.item.compatibleWith?.contains('protein') == true,
        )
        .toList();

    final availableSides = storeProvider.menuItems
        .where(
          (m) =>
              m.storeId == widget.item.storeId &&
              m.type == 'side' &&
              widget.item.compatibleWith?.contains('side') == true,
        )
        .toList();

    final availableDrinks = storeProvider.menuItems
        .where(
          (m) =>
              m.storeId == widget.item.storeId &&
              m.type == 'drink' &&
              widget.item.compatibleWith?.contains('drink') == true,
        )
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
        left: 24.w,
        right: 24.w,
        top: 24.h,
        bottom: 24.h + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        border: Border(top: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: textColor,
                      ),
                    ),
                    Text(
                      widget.item.description,
                      style: TextStyle(fontSize: 14.sp, color: mutedColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, size: 22.sp),
                style: IconButton.styleFrom(
                  backgroundColor: mutedColor.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // ── Scrollable options ──────────────────────────────────────────
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
                        children: widget.item.sizes
                            .map(
                              (size) => ListTile(
                                title: Text(
                                  size.name,
                                  style: TextStyle(color: textColor),
                                ),
                                trailing: Text(
                                  '₦${size.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: brandAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                leading: Radio<String>(
                                  value: size.id,
                                  activeColor: brandAccent,
                                ),
                                onTap: () =>
                                    setState(() => _selectedSizeId = size.id),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                  if (availableProteins.isNotEmpty) ...[
                    ItemDetailOptionsSection(
                      title: 'Add Protein',
                      children: availableProteins
                          .map(
                            (meat) => ItemDetailQuantityOption(
                              item: meat,
                              count: _selectedMeats[meat.id] ?? 0,
                              accentColor: brandAccent,
                              onChanged: (c) =>
                                  setState(() => _selectedMeats[meat.id] = c),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (availableSides.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    ItemDetailOptionsSection(
                      title: 'Add Sides',
                      children: availableSides
                          .map(
                            (side) => ItemDetailQuantityOption(
                              item: side,
                              count: _selectedSides[side.id] ?? 0,
                              accentColor: brandAccent,
                              onChanged: (c) =>
                                  setState(() => _selectedSides[side.id] = c),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (widget.item.type == 'swallow' ||
                      widget.item.compatibleWith?.contains('soup') == true) ...[
                    SizedBox(height: 24.h),
                    ItemDetailOptionsSection(
                      title: 'Choose a Soup',
                      subtitle: 'Required',
                      children: availableSoups
                          .map(
                            (soup) => ItemDetailSoupOption(
                              soup: soup,
                              isSelected: _selectedSoupId == soup.id,
                              accentColor: brandAccent,
                              onTap: () =>
                                  setState(() => _selectedSoupId = soup.id),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (availableDrinks.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    ItemDetailOptionsSection(
                      title: 'Add Drinks',
                      children: availableDrinks
                          .map(
                            (drink) => ItemDetailQuantityOption(
                              item: drink,
                              count: _selectedDrinks[drink.id] ?? 0,
                              accentColor: brandAccent,
                              onChanged: (c) =>
                                  setState(() => _selectedDrinks[drink.id] = c),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (availableAddons.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    ItemDetailOptionsSection(
                      title: 'Extras & Add-ons',
                      children: availableAddons
                          .map(
                            (addon) => ItemDetailQuantityOption(
                              item: addon,
                              count: _selectedAddons[addon.id] ?? 0,
                              accentColor: brandAccent,
                              onChanged: (c) =>
                                  setState(() => _selectedAddons[addon.id] = c),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // ── Bottom bar ──────────────────────────────────────────────────
          Row(
            children: [
              _quantityStepper(brandAccent, mutedColor, surfaceColor),
              SizedBox(width: 16.w),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      _handleAddToCart(cartProvider, storeProvider),
                  style: FilledButton.styleFrom(
                    backgroundColor: brandAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                    ),
                  ),
                  child: Text(
                    'Add to Cart • ₦${totalPrice.toStringAsFixed(0)}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quantity stepper ──────────────────────────────────────────────────────
  Widget _quantityStepper(Color accent, Color muted, Color surface) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accent.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: Icon(Icons.remove_rounded, size: 20.sp, color: accent),
            splashRadius: 20.r,
          ),
          Text(
            '$_quantity',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16.sp,
              color: accent,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: Icon(Icons.add_rounded, size: 20.sp, color: accent),
            splashRadius: 20.r,
          ),
        ],
      ),
    );
  }

  // ── Add to cart logic (unchanged, but dialog styled) ─────────────────────
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
      _showClearCartDialog(
        cartProvider: cartProvider,
        soupPayload: soupPayload,
      );
    }
  }

  void _showClearCartDialog({
    required CartProvider cartProvider,
    required Map<String, dynamic>? soupPayload,
  }) {
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
}
