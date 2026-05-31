import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../common/universal_image.dart';
import '../../models/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final Color accent;
  final VoidCallback onAdd;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.accent,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Adaptive colours from AppColors ────────────────────────────────────
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final cardBorder = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.4)
        : AppColors.lightBorder.withValues(alpha: 0.5);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final priceColor = accent; // brand colour for price
    final addBtnBg = accent;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.04);

    // ── Responsive dimensions ──────────────────────────────────────────────
    final borderRadius = 20.r;
    final imageSize = 90.w;
    final cardPadding = 12.w;
    final innerSpacing = 14.w;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: item.isReady ? () => context.push('/item/${item.id}') : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Opacity(
            opacity: item.isReady ? 1.0 : 0.5,
            child: Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: cardBorder, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image with out-of-stock overlay ──────────────────────
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: UniversalImage(
                          imageUrl: item.image,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            width: imageSize,
                            height: imageSize,
                            color: isDark
                                ? AppColors.darkSurface2
                                : AppColors.lightSurface,
                          ),
                        ),
                      ),
                      if (!item.isReady)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Center(
                              child: Text(
                                'OUT OF\nSTOCK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(width: innerSpacing),

                  // ── Content ──────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Popular badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.popular)
                              Padding(
                                padding: EdgeInsets.only(left: 4.w),
                                child: Icon(
                                  Icons.stars_rounded,
                                  color: accent,
                                  size: 18.sp,
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 4.h),

                        // Description
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

                        // Price + Add / Unavailable + Remaining
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Price
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₦${item.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w900,
                                    color: priceColor,
                                  ),
                                ),
                                if (item.isPerPortion)
                                  Text(
                                    ' / portion',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: mutedColor.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            if (item.portionsRemaining != null)
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: Text(
                                  item.portionsRemaining! > 0
                                      ? '${item.portionsRemaining} left'
                                      : '0 left',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: mutedColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Button
                            if (item.isReady)
                              SizedBox(
                                height: 34.h,
                                child: ElevatedButton(
                                  onPressed: onAdd,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: addBtnBg,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    elevation: 0,
                                    textStyle: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Add'),
                                ),
                              )
                            else
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? AppColors.darkSurface2
                                              : AppColors.lightSurface)
                                          .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
