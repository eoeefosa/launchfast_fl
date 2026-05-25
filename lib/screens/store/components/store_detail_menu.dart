import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../models/menu_item.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/common/universal_image.dart';

// Responsive constants
const double _kCategoryBarHeight = 52; // was 60
const double _kBorderRadius = 20; // was 24

// ─────────────────────────────────────────────────────────────────────────────
// Sticky category bar delegate
// ─────────────────────────────────────────────────────────────────────────────

class CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const CategoryHeaderDelegate({
    required this.categories,
    required this.onCategoryTap,
    required this.surfaceColor,
    required this.textColor,
    required this.chipBgColor,
    required this.borderColor,
  });

  final List<String> categories;
  final ValueChanged<int> onCategoryTap;
  final Color surfaceColor;
  final Color textColor;
  final Color chipBgColor;
  final Color borderColor;

  @override
  double get minExtent => _kCategoryBarHeight.h;

  @override
  double get maxExtent => _kCategoryBarHeight.h;

  @override
  bool shouldRebuild(CategoryHeaderDelegate oldDelegate) =>
      oldDelegate.categories != categories;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: surfaceColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: categories.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(right: 10.w),
          child: CategoryChip(
            label: categories[index],
            textColor: textColor,
            bgColor: chipBgColor,
            borderColor: borderColor,
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
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.sp,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category section (holds the menu items)
// ─────────────────────────────────────────────────────────────────────────────

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.category,
    required this.items,
    required this.categoryKey,
    required this.cartProvider,
    required this.accentColor,
    required this.storeIsOpen,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.chipBgColor,
    required this.borderColor,
  });

  final String category;
  final List<MenuItem> items;
  final GlobalKey categoryKey;
  final CartProvider cartProvider;
  final Color accentColor;
  final bool storeIsOpen;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color chipBgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: surfaceColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              key: categoryKey,
              padding: EdgeInsets.only(top: 4.h, bottom: 14.h),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
              ),
            ),
            for (final item in items)
              MenuItemCard(
                item: item,
                accentColor: accentColor,
                storeIsOpen: storeIsOpen,
                surfaceColor: surfaceColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                chipBgColor: chipBgColor,
              ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual menu item card
// ─────────────────────────────────────────────────────────────────────────────

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.accentColor,
    required this.storeIsOpen,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
    required this.chipBgColor,
  });

  final MenuItem item;
  final Color accentColor;
  final bool storeIsOpen;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;
  final Color chipBgColor;

  bool get _isInteractive => storeIsOpen && item.isReady;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Semantics(
        button: _isInteractive,
        label: 'View details for ${item.name}',
        hint: _isInteractive ? 'Opens item details' : 'Item unavailable',
        child: InkWell(
          onTap: _isInteractive ? () => context.push('/item/${item.id}') : null,
          borderRadius: BorderRadius.circular(_kBorderRadius.r),
          child: Opacity(
            opacity: _isInteractive ? 1.0 : 0.6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(_kBorderRadius.r),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Row(
                  children: [
                    ItemImage(imageUrl: item.image),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: ItemDetails(
                        item: item,
                        isInteractive: _isInteractive,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        accentColor: accentColor,
                        chipBgColor: chipBgColor,
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
      borderRadius: BorderRadius.circular(16.r),
      child: UniversalImage(
        imageUrl: imageUrl,
        width: 96.w,
        height: 96.h,
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
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.chipBgColor,
  });

  final MenuItem item;
  final bool isInteractive;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final Color chipBgColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: textColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          item.description,
          style: TextStyle(
            fontSize: 12.sp,
            color: mutedColor,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₦${item.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            if (isInteractive)
              AddButton(accentColor: accentColor, chipBgColor: chipBgColor),
          ],
        ),
      ],
    );
  }
}

class AddButton extends StatelessWidget {
  const AddButton({
    super.key,
    required this.accentColor,
    required this.chipBgColor,
  });

  final Color accentColor;
  final Color chipBgColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add to cart',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
