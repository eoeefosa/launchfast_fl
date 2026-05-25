import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../providers/auth_provider.dart';
import '../sheets/edit_profile_sheet.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, required this.auth});

  final dynamic user;
  final AuthProvider auth;

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return Padding(
      padding: EdgeInsets.all(20.r), // reduced from 24
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.1),
                    width: 3.w, // slightly thinner
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.1),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 34.r, // was 38
                  backgroundColor: primaryColor.withValues(alpha: 0.05),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 28.sp, // was 32
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 1.w,
                right: 1.w,
                child: Container(
                  padding: EdgeInsets.all(3.r), // was 4
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: surfaceColor, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 9.sp,
                    color: Colors.white,
                  ), // was 10
                ),
              ),
            ],
          ).animate().scale(
            delay: 100.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          SizedBox(width: 16.w), // was 20
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Campus Chow User',
                  style: TextStyle(
                    fontSize: 20.sp, // was 24
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: textColor,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),
                Text(
                  user.email,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13.sp, // was 14
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),
                SizedBox(height: 8.h), // was 10
                _RoleBadge(role: user.role),
              ],
            ),
          ),
          Material(
            color: primaryColor.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: () => _showEditModal(context),
              icon: Icon(
                Icons.edit_rounded,
                size: 18.sp,
                color: primaryColor,
              ), // was 20
              padding: EdgeInsets.all(8.r), // ensure touch target
              constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), // reduced
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Text(
        role.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 9.sp, // was 10
          fontWeight: FontWeight.w900,
          color: primaryColor,
          letterSpacing: 1,
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5);
  }
}
