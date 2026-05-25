import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/store_provider.dart';
import '../models/store.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final stores = storeProvider.stores;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.2)
        : AppColors.lightBorder.withValues(alpha: 0.4);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.04);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'All Stores',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontSize: 20.sp,
            color: textColor,
          ),
        ),
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return _buildStoreCard(
            context,
            store,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            shadowColor: shadowColor,
            textColor: textColor,
            mutedColor: mutedColor,
          );
        },
      ),
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    Store store, {
    required Color surfaceColor,
    required Color borderColor,
    required Color shadowColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    final accentColor = store.accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h), // 24 → 16
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20.r), // 24 → 20
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: () => context.push('/store/${store.id}'),
          child: Column(
            children: [
              // Store Banner
              Stack(
                children: [
                  Container(
                    height: 110.h, // 140 → 110
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 44.sp, // 56 → 44
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  // Delivery Time Badge
                  Positioned(
                    bottom: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ), // 10/6 → 8/4
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 12.sp, // 14 → 12
                            color: textColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            store.deliveryTime,
                            style: TextStyle(
                              fontSize: 10.sp, // 12 → 10
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Closed Overlay
                  if (!store.isOpen)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'CLOSED',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Store Info
              Padding(
                padding: EdgeInsets.all(16.r), // 20 → 16
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: TextStyle(
                              fontSize: 18.sp, // 20 → 18
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14.sp, // 16 → 14
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                store.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12.sp, // 14 → 12
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h), // 6 → 4
                    Text(
                      store.tagline,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12.sp, // 14 → 12
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.h), // 16 → 12
                    Divider(color: borderColor, height: 1, thickness: 1),
                    SizedBox(height: 12.h), // 16 → 12
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
