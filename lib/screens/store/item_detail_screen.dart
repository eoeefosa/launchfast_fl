import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';
import '../../constants/static_data.dart';

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
    Future.delayed(
      const Duration(milliseconds: 180),
      _contentController.forward,
    );
    Future.delayed(
      const Duration(milliseconds: 320),
      _footerController.forward,
    );
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  // ── Derived data ───────────────────────────

  double _computeTotal(
    MenuItem item,
    List<MenuItem> availableSoups,
    List<MenuItem> availableAddons,
  ) {
    var total = item.price;
    _selectedMeats.forEach(
      (type, count) => total += (StaticData.meatPrices[type] ?? 0) * count,
    );
    if (_hasSalad) total += StaticData.saladPrice;
    if (_selectedSoupId != null) {
      final soup = availableSoups.firstWhere((s) => s.id == _selectedSoupId);
      if (!soup.isFreeWithSwallow) total += soup.price;
    }
    _selectedAddons.forEach((id, count) {
      final addon = availableAddons.firstWhere((m) => m.id == id);
      total += addon.price * count;
    });
    return total * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final item = storeProvider.menuItems.firstWhere((m) => m.id == widget.id);
    final store = StaticData.stores.firstWhere((s) => s.id == item.storeId);
    final accentColor = Color(
      int.parse(store.accentColor.replaceFirst('#', '0xFF')),
    );

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

    final totalPrice = _computeTotal(item, availableSoups, availableAddons);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            _ScrollBody(
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
              onMeatChanged: (type, count) =>
                  setState(() => _selectedMeats[type] = count),
              onAddonChanged: (id, count) =>
                  setState(() => _selectedAddons[id] = count),
              onSaladChanged: (val) => setState(() => _hasSalad = val),
              onSoupSelected: (id) => setState(() => _selectedSoupId = id),
            ),
            SlideTransition(
              position: _footerSlide,
              child: Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _Footer(
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

  void _addSoupIfNeeded(
    CartProvider cartProvider,
    StoreProvider storeProvider,
  ) {
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
      builder: (_) => _ClearCartDialog(
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

// ─────────────────────────────────────────────
//  Scrollable body
// ─────────────────────────────────────────────

class _ScrollBody extends StatelessWidget {
  final AnimationController heroController;
  final Animation<double> heroScale;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;

  final MenuItem item;
  final dynamic store;
  final Color accentColor;
  final List<MenuItem> availableSoups;
  final List<MenuItem> availableAddons;

  final Map<String, int> selectedMeats;
  final Map<String, int> selectedAddons;
  final bool hasSalad;
  final String? selectedSoupId;
  final bool isDark;

  final void Function(String type, int count) onMeatChanged;
  final void Function(String id, int count) onAddonChanged;
  final void Function(bool val) onSaladChanged;
  final void Function(String id) onSoupSelected;

  const _ScrollBody({
    required this.heroController,
    required this.heroScale,
    required this.contentFade,
    required this.contentSlide,
    required this.item,
    required this.store,
    required this.accentColor,
    required this.availableSoups,
    required this.availableAddons,
    required this.selectedMeats,
    required this.selectedAddons,
    required this.hasSalad,
    required this.selectedSoupId,
    required this.isDark,
    required this.onMeatChanged,
    required this.onAddonChanged,
    required this.onSaladChanged,
    required this.onSoupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroImage(imageUrl: item.image, heroScale: heroScale),
          FadeTransition(
            opacity: contentFade,
            child: SlideTransition(
              position: contentSlide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ItemHeader(
                      item: item,
                      store: store,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 32),
                    _OptionsSection(
                      title: 'Add Meat',
                      children: [
                        _MeatOption(
                          type: 'Small',
                          price: StaticData.meatPrices['Small']!,
                          count: selectedMeats['Small']!,
                          accentColor: accentColor,
                          onChanged: (c) => onMeatChanged('Small', c),
                        ),
                        _MeatOption(
                          type: 'Big',
                          price: StaticData.meatPrices['Big']!,
                          count: selectedMeats['Big']!,
                          accentColor: accentColor,
                          onChanged: (c) => onMeatChanged('Big', c),
                        ),
                      ],
                    ),
                    if (availableAddons.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _OptionsSection(
                        title: 'Add-ons',
                        children: availableAddons
                            .map(
                              (addon) => _AddonOption(
                                addon: addon,
                                count: selectedAddons[addon.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onAddonChanged(addon.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (item.category == 'Rice' || item.name == 'Moi Moi') ...[
                      const SizedBox(height: 32),
                      _OptionsSection(
                        title: 'Extras',
                        children: [
                          _SaladOption(
                            hasSalad: hasSalad,
                            accentColor: accentColor,
                            onChanged: onSaladChanged,
                          ),
                        ],
                      ),
                    ],
                    if (item.category == 'Swallow') ...[
                      const SizedBox(height: 32),
                      _OptionsSection(
                        title: 'Choose a Soup',
                        subtitle: 'Required',
                        children: availableSoups
                            .map(
                              (soup) => _SoupOption(
                                soup: soup,
                                isSelected: selectedSoupId == soup.id,
                                accentColor: accentColor,
                                onTap: () => onSoupSelected(soup.id),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Hero image with close button
// ─────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final Animation<double> heroScale;

  const _HeroImage({required this.imageUrl, required this.heroScale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ScaleTransition(
            scale: heroScale,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, _, _) => Container(
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
          // Gradient overlay for legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _CloseButton(onPressed: () => context.pop()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Close button
// ─────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Item header — name, price, store badge
// ─────────────────────────────────────────────

class _ItemHeader extends StatelessWidget {
  final MenuItem item;
  final dynamic store;
  final Color accentColor;
  final bool isDark;

  const _ItemHeader({
    required this.item,
    required this.store,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.white70 : Colors.grey[600];
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.grey[100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₦${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: -0.5,
                  ),
                ),
                if (item.isPerPortion)
                  Text(
                    '/ portion',
                    style: TextStyle(fontSize: 11, color: labelColor),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          item.description,
          style: TextStyle(fontSize: 15, color: labelColor, height: 1.6),
        ),
        const SizedBox(height: 18),
        _StoreBadge(
          storeName: store.name,
          accentColor: accentColor,
          surfaceColor: surfaceColor!,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Store badge
// ─────────────────────────────────────────────

class _StoreBadge extends StatelessWidget {
  final String storeName;
  final Color accentColor;
  final Color surfaceColor;

  const _StoreBadge({
    required this.storeName,
    required this.accentColor,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
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
            'From $storeName',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Options section wrapper
// ─────────────────────────────────────────────

class _OptionsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _OptionsSection({
    required this.title,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Shared selection item card
// ─────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
        : isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.grey[200]!;
    final bgColor = isDark
        ? (isSelected
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.03))
        : (isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
              : Colors.white);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stepper control (shared across meat & addon)
// ─────────────────────────────────────────────

class _StepperControl extends StatelessWidget {
  final int count;
  final Color accentColor;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperControl({
    required this.count,
    required this.accentColor,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimColor = isDark ? Colors.white24 : Colors.black12;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          color: count > 0 ? accentColor : dimColor,
          onTap: count > 0 ? onDecrement : null,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            '$count',
            key: ValueKey(count),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          color: accentColor,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Meat option
// ─────────────────────────────────────────────

class _MeatOption extends StatelessWidget {
  final String type;
  final double price;
  final int count;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const _MeatOption({
    required this.type,
    required this.price,
    required this.count,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: '$type Meat',
      subtitle: '+₦${price.toStringAsFixed(2)}',
      isSelected: count > 0,
      trailing: _StepperControl(
        count: count,
        accentColor: accentColor,
        onDecrement: () => onChanged(count - 1),
        onIncrement: () => onChanged(count + 1),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Addon option
// ─────────────────────────────────────────────

class _AddonOption extends StatelessWidget {
  final MenuItem addon;
  final int count;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const _AddonOption({
    required this.addon,
    required this.count,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: addon.name,
      subtitle: '+₦${addon.price.toStringAsFixed(2)}',
      isSelected: count > 0,
      trailing: _StepperControl(
        count: count,
        accentColor: accentColor,
        onDecrement: () => onChanged(count - 1),
        onIncrement: () => onChanged(count + 1),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Salad option
// ─────────────────────────────────────────────

class _SaladOption extends StatelessWidget {
  final bool hasSalad;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _SaladOption({
    required this.hasSalad,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: 'Fresh Salad',
      subtitle: '+₦${StaticData.saladPrice.toStringAsFixed(2)}',
      isSelected: hasSalad,
      onTap: () => onChanged(!hasSalad),
      trailing: _AnimatedCheckbox(
        value: hasSalad,
        accentColor: accentColor,
        onChanged: onChanged,
      ),
    );
  }
}

class _AnimatedCheckbox extends StatelessWidget {
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _AnimatedCheckbox({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? accentColor : Colors.grey.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Soup option
// ─────────────────────────────────────────────

class _SoupOption extends StatelessWidget {
  final MenuItem soup;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _SoupOption({
    required this.soup,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: soup.name,
      subtitle: soup.isFreeWithSwallow
          ? 'Free with swallow'
          : '₦${soup.price.toStringAsFixed(2)}',
      isSelected: isSelected,
      onTap: onTap,
      trailing: _RadioDot(isSelected: isSelected, accentColor: accentColor),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool isSelected;
  final Color accentColor;

  const _RadioDot({required this.isSelected, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────
//  Bottom footer — quantity + add to cart
// ─────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final double totalPrice;
  final Color accentColor;
  final bool isDark;
  final String? selectedSoupId;
  final Map<String, int> selectedMeats;
  final bool hasSalad;
  final Map<String, int> selectedAddons;
  final List<MenuItem> availableSoups;
  final CartProvider cartProvider;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  const _Footer({
    required this.item,
    required this.quantity,
    required this.totalPrice,
    required this.accentColor,
    required this.isDark,
    required this.selectedSoupId,
    required this.selectedMeats,
    required this.hasSalad,
    required this.selectedAddons,
    required this.availableSoups,
    required this.cartProvider,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderTop = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey[200]!;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: surfaceBg,
        border: Border(top: BorderSide(color: borderTop, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _QuantityStepper(
            quantity: quantity,
            accentColor: accentColor,
            isDark: isDark,
            onDecrement: () {
              if (quantity > 1) onQuantityChanged(quantity - 1);
            },
            onIncrement: () => onQuantityChanged(quantity + 1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _AddToCartButton(
              totalPrice: totalPrice,
              accentColor: accentColor,
              onTap: onAddToCart,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.accentColor,
    required this.isDark,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey[100]!;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FooterStepButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            enabled: quantity > 1,
            accentColor: accentColor,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          _FooterStepButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            enabled: true,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class _FooterStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color accentColor;

  const _FooterStepButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? accentColor : Colors.grey.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatefulWidget {
  final double totalPrice;
  final Color accentColor;
  final VoidCallback onTap;

  const _AddToCartButton({
    required this.totalPrice,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _pressController.forward();
  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Add to Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '₦${widget.totalPrice.toStringAsFixed(2)}',
                    key: ValueKey(widget.totalPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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
}

// ─────────────────────────────────────────────
//  Clear cart dialog
// ─────────────────────────────────────────────

class _ClearCartDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _ClearCartDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Start a new order?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: Text(
        'Your cart has items from another store. Clear it and add this item?',
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey[600],
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text(
            'Clear & Add',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
