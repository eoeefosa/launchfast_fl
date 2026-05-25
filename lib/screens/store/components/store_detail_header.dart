import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

class StoreHeader extends StatelessWidget {
  const StoreHeader({
    super.key,
    required this.store,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
    required this.statBgColor,
  });

  final dynamic store;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;
  final Color statBgColor;

  @override
  Widget build(BuildContext context) {
    final accentColor = store.accentColor as Color;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.name as String,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: textColor,
                    ),
                  ),
                ),
                FavouriteButton(
                  accentColor: accentColor,
                  storeId: store.id as String,
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              store.tagline as String,
              style: TextStyle(
                fontSize: 13.sp,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                StatBadge(
                  icon: Icons.star_rounded,
                  label: store.rating.toString(),
                  iconColor: Colors.amber,
                  textColor: textColor,
                  bgColor: statBgColor,
                  borderColor: borderColor,
                ),
                SizedBox(width: 8.w),
                StatBadge(
                  icon: Icons.access_time_filled_rounded,
                  label: store.deliveryTime as String,
                  iconColor: Colors.blue,
                  textColor: textColor,
                  bgColor: statBgColor,
                  borderColor: borderColor,
                ),
                SizedBox(width: 8.w),
                StatBadge(
                  icon: Icons.delivery_dining_rounded,
                  label: 'Free',
                  iconColor: Colors.green,
                  textColor: textColor,
                  bgColor: statBgColor,
                  borderColor: borderColor,
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}

class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.accentColor,
    required this.storeId,
  });

  final Color accentColor;
  final String storeId;

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<AuthProvider, bool>(
      (auth) => auth.user?.favoriteStores.contains(storeId) ?? false,
    );
    final isAuthenticated = context.select<AuthProvider, bool>(
      (auth) => auth.isAuthenticated,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          color: accentColor,
          size: 20.sp,
        ),
        onPressed: !isAuthenticated
            ? null
            : () async {
                try {
                  await context.read<AuthProvider>().toggleFavorite(storeId);
                  if (context.mounted) {
                    HapticFeedback.mediumImpact();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update favorite: $e')),
                    );
                  }
                }
              },
        padding: EdgeInsets.all(8.r),
        constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
      ),
    );
  }
}

class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: iconColor),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
