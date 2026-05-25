import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Fixed height of the sticky category selector header.
const double kCategoryHeaderHeight = 76;

class CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  CategoryHeaderDelegate({required this.backgroundColor, required this.child});

  final Color backgroundColor;
  final Widget child;

  @override
  double get minExtent => kCategoryHeaderHeight.h; // responsive height

  @override
  double get maxExtent => kCategoryHeaderHeight.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : AppColors.lightBorder.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant CategoryHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
