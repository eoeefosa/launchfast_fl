import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'location_selector.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── AppColors for light/dark ────────────────────────────────────────
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h), // tightened
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Greeting & name row ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 10.sp, // 11 → 10
                        color: mutedColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 1.h), // 2 → 1
                    Text(
                      (user?.name != null && user!.name.isNotEmpty)
                          ? '${user.name} 👋'
                          : 'Guest User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20.sp, // 22 → 20
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderActions(
                user: user,
                primaryColor: primaryColor,
                isDark: isDark,
                surfaceColor: surfaceColor,
                mutedColor: mutedColor,
              ),
            ],
          ),
          SizedBox(height: 20.h), // 24 → 20
          // ── Location + Search ────────────────────────────────────────
          Row(
            children: [
              Expanded(child: LocationSelector()),
              SizedBox(width: 10.w), // 12 → 10
              Semantics(
                label: 'Search for food',
                button: true,
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Tooltip(
                    message: 'Search',
                    child: Container(
                      width: 44.w, // 48 → 44
                      height: 44.h, // 48 → 44
                      decoration: BoxDecoration(
                        color: isDark
                            ? primaryColor.withValues(alpha: 0.15)
                            : primaryColor,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: isDark ? primaryColor : Colors.white,
                        size: 20.sp, // 22 → 20
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header actions – notification bell + profile avatar
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderActions extends StatelessWidget {
  final dynamic user;
  final Color primaryColor;
  final bool isDark;
  final Color surfaceColor;
  final Color mutedColor;

  const _HeaderActions({
    required this.user,
    required this.primaryColor,
    required this.isDark,
    required this.surfaceColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Notification icon with badge
        Semantics(
          label: 'Notifications',
          button: true,
          child: GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Tooltip(
              message: 'Notifications',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44.w, // 48 → 44
                    height: 44.h, // 48 → 44
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface2.withValues(alpha: 0.5)
                          : AppColors.lightSurface.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.3)
                            : AppColors.lightBorder.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 22.sp, // 26 → 22
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightText,
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, child) {
                      if (provider.unreadCount == 0) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        right: -2.w,
                        top: -2.h,
                        child: Container(
                          padding: EdgeInsets.all(3.r),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: surfaceColor, width: 2),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18.w, // 20 → 18
                            minHeight: 18.h, // 20 → 18
                          ),
                          child: Text(
                            '${provider.unreadCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp, // 10 → 9
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w), // 12 → 10
        // Profile avatar
        Semantics(
          label: 'View Profile',
          button: true,
          child: GestureDetector(
            onTap: () => context.go('/profile'),
            child: Tooltip(
              message: 'Profile',
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: isDark ? 0.6 : 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18.r, // 20 → 18
                    backgroundColor: isDark
                        ? primaryColor.withValues(alpha: 0.25)
                        : primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      (user?.name != null && user!.name.trim().isNotEmpty)
                          ? user!.name.trim()[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isDark ? Colors.white : primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.sp, // 16 → 14
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
