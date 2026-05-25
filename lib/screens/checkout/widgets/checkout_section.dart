import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutSection extends StatelessWidget {
  const CheckoutSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── AppColors adapt ──────────────────────────────────────────────────
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.5)
        : AppColors.lightBorder.withValues(alpha: 0.5);
    final titleColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.04);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 8),
              color: shadowColor,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              SizedBox(height: 18.h),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
