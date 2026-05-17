import 'package:flutter/material.dart';

/// Fixed height of the sticky category selector header.
const double kCategoryHeaderHeight = 76;

/// [SliverPersistentHeaderDelegate] that pins the category selector to the
/// top of the scroll view.
///
/// [minExtent] == [maxExtent] makes this a fixed-height header — it does not
/// shrink as the user scrolls, matching the original's intent.
class CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  CategoryHeaderDelegate({
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  double get minExtent => kCategoryHeaderHeight;

  @override
  double get maxExtent => kCategoryHeaderHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox.expand(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CategoryHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
