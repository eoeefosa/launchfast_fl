import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart'; // adjust path
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
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 8.h),
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
                      fontSize: 20.sp, // 24 → 18
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 2.h), // 4 → 2
                  Text(
                    'Hand-picked for your taste',
                    style: TextStyle(
                      fontSize: 13.sp, // 14 → 12
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/stores'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Explore All',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
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
