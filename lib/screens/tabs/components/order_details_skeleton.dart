import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OrderDetailsSkeleton extends StatelessWidget {
  const OrderDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? Colors.white10 : Colors.black12;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status/Header skeleton
          Container(
            height: 100.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
          SizedBox(height: 32.h),
          // Receipt/List skeleton
          ...List.generate(4, (index) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Container(
              height: 50.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          )),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .shimmer(duration: 1.5.seconds, color: isDark ? Colors.white24 : Colors.white60);
  }
}
