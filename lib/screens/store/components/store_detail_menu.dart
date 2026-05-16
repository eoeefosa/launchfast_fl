import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/menu_item.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/common/universal_image.dart';

const _kCategoryBarHeight = 60.0;
const _kBorderRadius = 24.0;

class CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const CategoryHeaderDelegate({
    required this.categories,
    required this.onCategoryTap,
  });

  final List<String> categories;
  final ValueChanged<int> onCategoryTap;

  @override
  double get minExtent => _kCategoryBarHeight;

  @override
  double get maxExtent => _kCategoryBarHeight;

  @override
  bool shouldRebuild(CategoryHeaderDelegate oldDelegate) =>
      oldDelegate.categories != categories;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CategoryChip(
            label: categories[index],
            scheme: scheme,
            onTap: () => onCategoryTap(index),
          ),
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.scheme,
    required this.onTap,
  });

  final String label;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.category,
    required this.items,
    required this.categoryKey,
    required this.cartProvider,
    required this.accentColor,
    required this.storeIsOpen,
    required this.scheme,
  });

  final String category;
  final List<MenuItem> items;
  final GlobalKey categoryKey;
  final CartProvider cartProvider;
  final Color accentColor;
  final bool storeIsOpen;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              key: categoryKey,
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            for (final item in items)
              MenuItemCard(
                item: item,
                accentColor: accentColor,
                storeIsOpen: storeIsOpen,
                scheme: scheme,
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.accentColor,
    required this.storeIsOpen,
    required this.scheme,
  });

  final MenuItem item;
  final Color accentColor;
  final bool storeIsOpen;
  final ColorScheme scheme;

  bool get _isInteractive => storeIsOpen && item.isReady;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Semantics(
        button: _isInteractive,
        label: 'View details for ${item.name}',
        hint: _isInteractive ? 'Opens item details' : 'Item unavailable',
        child: InkWell(
          onTap: _isInteractive ? () => context.push('/item/${item.id}') : null,
          borderRadius: BorderRadius.circular(_kBorderRadius),
          child: Opacity(
            opacity: _isInteractive ? 1.0 : 0.6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(_kBorderRadius),
                border: Border.all(color: scheme.outlineVariant, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ItemImage(imageUrl: item.image),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ItemDetails(
                        item: item,
                        isInteractive: _isInteractive,
                        scheme: scheme,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ItemImage extends StatelessWidget {
  const ItemImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: UniversalImage(
        imageUrl: imageUrl,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
      ),
    );
  }
}

class ItemDetails extends StatelessWidget {
  const ItemDetails({
    super.key,
    required this.item,
    required this.isInteractive,
    required this.scheme,
  });

  final MenuItem item;
  final bool isInteractive;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.description,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.6),
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₦${item.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            if (isInteractive) AddButton(scheme: scheme, itemName: item.name),
          ],
        ),
      ],
    );
  }
}

class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.scheme, required this.itemName});

  final ColorScheme scheme;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add $itemName to cart',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: scheme.onPrimary, size: 18),
              const SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
