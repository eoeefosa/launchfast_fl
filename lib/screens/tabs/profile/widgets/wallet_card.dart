import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../providers/auth_provider.dart';
import '../sheets/top_up_sheet.dart';
import '../sheets/transfer_sheet.dart';
import '../sheets/redeem_sheet.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({super.key, required this.auth});

  final AuthProvider auth;

  void _showTopUpModal(BuildContext context) {
    TopUpDialog.show(context, auth);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 10.h,
      ), // slightly less vertical
      height: 200.h, // reduced from 230
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r), // 32 → 28
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background circles – scaled down
          Positioned(
            right: -30.w,
            top: -30.h,
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -15.w,
            bottom: -15.h,
            child: Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.r), // 24 → 20
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r), // 8 → 6
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r), // 10 → 8
                          ),
                          child: Icon(
                            Icons.wallet_rounded,
                            color: Colors.white,
                            size: 16.sp, // 18 → 16
                          ),
                        ),
                        SizedBox(width: 10.w), // 12 → 10
                        Text(
                          'CampusChow Wallet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp, // 14 → 13
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white70,
                      size: 18.sp, // 20 → 18
                    ),
                  ],
                ),
                const Spacer(),
                // Balance label & amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp, // 12 → 11
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h), // 4 → 2
                    Text(
                      '₦${NumberFormat('#,##0.00').format(auth.user!.walletBalance)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30.sp, // 38 → 30
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ).animate().shimmer(
                      duration: 2.seconds,
                      color: Colors.white24,
                    ),
                  ],
                ),
                const Spacer(),
                // Deposit button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showTopUpModal(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: Text('Deposit', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, letterSpacing: 0.4)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => TransferSheet.show(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: Text('Transfer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, letterSpacing: 0.4)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => RedeemSheet.show(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: Text('Redeem', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, letterSpacing: 0.4)),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.15),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }
}
