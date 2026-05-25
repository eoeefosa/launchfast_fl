import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final List<String> categories;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Standard icon mapping
    IconData getIcon(String label) {
      switch (label.toLowerCase()) {
        case 'all':
          return Icons.restaurant_rounded;
        case 'rice':
          return Icons.rice_bowl_rounded;
        case 'swallow':
          return Icons.cookie_rounded;
        case 'soup':
          return Icons.soup_kitchen_rounded;
        case 'drinks':
          return Icons.local_drink_rounded;
        case 'extras':
          return Icons.add_circle_outline_rounded;
        case 'others':
          return Icons.more_horiz_rounded;
        default:
          return Icons.fastfood_rounded;
      }
    }

    final allCategories = ['All', ...categories.where((c) => c != 'All')];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: allCategories.map((label) {
            final isActive = selectedCategory == label;

            return Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: _CategoryChip(
                label: label,
                icon: getIcon(label),
                isActive: isActive,
                isDark: isDark,
                onTap: () => onCategorySelected(label),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final inactiveTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final inactiveBorderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.5)
        : AppColors.lightBorder.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive ? brandColor : surfaceColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive ? brandColor : inactiveBorderColor,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: isDark
                        ? brandColor.withValues(alpha: 0.3)
                        : brandColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isActive ? Colors.white : inactiveTextColor,
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : inactiveTextColor,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14.sp,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
