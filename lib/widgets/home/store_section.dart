import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/store.dart';
import 'store_tabs.dart';

class StoreSection extends StatelessWidget {
  final List<Store> stores;
  final String activeStoreId;
  final Function(String) onStoreSelected;
  final Color accentColor;

  const StoreSection({
    super.key,
    required this.stores,
    required this.activeStoreId,
    required this.onStoreSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── AppColors for light/dark ────────────────────────────────────────
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    // Keep the store’s own accent colour (passed from HomeScreen)
    final effectiveAccent = accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Kitchens',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Hand-picked for your taste',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/stores'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  backgroundColor: effectiveAccent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Explore All',
                  style: TextStyle(
                    color: effectiveAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        StoreTabs(
          stores: stores,
          activeStoreId: activeStoreId,
          onSelect: onStoreSelected,
        ),
      ],
    );
  }
}
