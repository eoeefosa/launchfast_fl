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
              Icon(
                Icons.search_off_rounded,
                size: 56.sp,
                color: mutedIcon,
              ), // 64 → 56
              SizedBox(height: 12.h), // 16 → 12
              Text(
                emptyMessage ?? 'No items found',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightMuted,
                  fontSize: 14.sp, // 16 → 14
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
            offset: Offset(
              0,
              20.h * (1 - value),
            ), // 30.h → 20.h (less translation)
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              16.w,
              20.h,
              16.w,
              8.h,
            ), // 20.w → 16.w, 28.h → 20.h, 12.h → 8.h
            child: Row(
              children: [
                Container(
                  width: 4.w,
                  height: 16.h, // 18.h → 16.h
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 8.w), // 10.w → 8.w
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp, // 13.sp → 12.sp
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2, // 1.4 → 1.2
                    color: textColor,
                  ),
                ),
                SizedBox(width: 8.w), // 10.w → 8.w
                Text(
                  '${items.length} items',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: mutedColor,
                  ), // 12.sp → 11.sp
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12.sp,
                  color: mutedColor,
                ), // 14.sp → 12.sp
              ],
            ),
          ),
          // Cards
          ...List.generate(items.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                left: 14.w, // 16.w → 14.w
                right: 14.w,
                bottom: i < items.length - 1
                    ? 10.h
                    : 16.h, // 12.h → 10.h, 20.h → 16.h
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
