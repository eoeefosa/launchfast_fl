import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/menu_item.dart';
import 'menu_item_card.dart';

class MenuGroupedList extends StatelessWidget {
  final Map<String, List<MenuItem>> groupedItems;
  final Color accentColor;
  final Function(MenuItem) onAdd;
  final String? emptyMessage;

  const MenuGroupedList({
    super.key,
    required this.groupedItems,
    required this.accentColor,
    required this.onAdd,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedIcon =
        (isDark ? AppColors.darkTextSecondary : AppColors.lightMuted)
            .withValues(alpha: 0.4);

    if (groupedItems.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64.sp, color: mutedIcon),
              SizedBox(height: 16.h),
              Text(
                emptyMessage ?? 'No items found',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightMuted,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final category = groupedItems.keys.elementAt(index);
        final items = groupedItems[category]!;

        return _CategoryGroup(
          category: category,
          items: items,
          accentColor: accentColor,
          onAdd: onAdd,
          index: index,
        );
      }, childCount: groupedItems.length),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<MenuItem> items;
  final Color accentColor;
  final Function(MenuItem) onAdd;
  final int index;

  const _CategoryGroup({
    required this.category,
    required this.items,
    required this.accentColor,
    required this.onAdd,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30.h * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 12.h),
            child: Row(
              children: [
                Container(
                  width: 4.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: textColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${items.length} items',
                  style: TextStyle(fontSize: 12.sp, color: mutedColor),
                ),
                const Spacer(),
                // Optional: a subtle see‑all arrow, remove if not needed
                Icon(Icons.arrow_forward_ios, size: 14.sp, color: mutedColor),
              ],
            ),
          ),
          // Cards
          ...List.generate(items.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: i < items.length - 1 ? 12.h : 20.h,
              ),
              child: MenuItemCard(
                item: items[i],
                accent: accentColor,
                onAdd: () => onAdd(items[i]),
              ),
            );
          }),
        ],
      ),
    );
  }
}
