import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/home/location_selector.dart';

// Broken down components
import 'widgets/profile_header.dart';
import 'widgets/wallet_card.dart';
import 'widgets/settings_tile.dart';
import 'widgets/verification_tile.dart';
import 'widgets/delete_account_button.dart';
import 'widgets/logout_button.dart';
import 'widgets/theme_switcher.dart';
import 'widgets/unauthenticated_view.dart';
import 'sheets/verification_sheet.dart';
import '../../../widgets/set_pin_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const UnauthenticatedView();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS = Platform.isIOS;

    // ── AppColors scaffold & app bar ──────────────────────────────────────
    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
        centerTitle: false,
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22.sp, // tightened from 28
            letterSpacing: -1,
            color: textColor,
          ),
        ),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          await Future.wait([auth.refreshUser()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(user: user, auth: auth),

              WalletCard(auth: auth),

              const SectionHeader(title: 'Activity'),
              ProfileSettingsTile(
                icon: isIOS
                    ? CupertinoIcons.list_bullet_indent
                    : Icons.history_rounded,
                title: 'Transaction History',
                subtitle: 'View your deposits and spending',
                onTap: () => context.push('/profile/transactions'),
              ),
              ProfileSettingsTile(
                icon: isIOS
                    ? CupertinoIcons.gift
                    : Icons.card_giftcard,
                title: 'Buy Gift Card',
                subtitle: 'Purchase a gift card for yourself or a friend',
                onTap: () => context.push('/profile/buy-gift-card'),
              ),
              ProfileSettingsTile(
                icon: isIOS ? CupertinoIcons.lock : Icons.lock_outline,
                title: user.hasTransactionPin ? 'Change Transaction PIN' : 'Set Transaction PIN',
                subtitle: user.hasTransactionPin
                    ? 'Update your 4-digit transaction PIN'
                    : 'Secure your transfers and payments with a PIN',
                onTap: () => SetPinSheet.show(context),
              ),
              ProfileSettingsTile(
                icon: isIOS
                    ? CupertinoIcons.star
                    : Icons.emoji_events_outlined,
                title: 'Cashback Winners',
                subtitle: 'See who won recently!',
                onTap: () => context.push('/profile/cashback-winners'),
              ),
              ProfileSettingsTile(
                icon: Icons.receipt_long_rounded,
                title: 'Verify Payment',
                subtitle: 'Payment failed but you were debited? Fix it here.',
                onTap: () => context.push('/verify-payment'),
              ),

              const SectionHeader(title: 'Account Verification'),
              VerificationTile(
                icon: user.emailVerified
                    ? (isIOS
                          ? CupertinoIcons.mail_solid
                          : Icons.mark_email_read)
                    : (isIOS ? CupertinoIcons.mail : Icons.mark_email_unread),
                title: 'Email Verification',
                verified: user.emailVerified,
                onTap: user.emailVerified
                    ? null
                    : () => _showVerificationModal(context, auth, 'email'),
              ),
              VerificationTile(
                icon: user.phoneVerified
                    ? (isIOS
                          ? CupertinoIcons.checkmark_seal_fill
                          : Icons.verified)
                    : (isIOS
                          ? CupertinoIcons.device_phone_portrait
                          : Icons.phone_android),
                title: 'Phone Verification',
                verified: user.phoneVerified,
                onTap: user.phoneVerified
                    ? null
                    : () => _showVerificationModal(context, auth, 'phone'),
              ),

              const SectionHeader(title: 'Preferences'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: const LocationSelector(),
              ),
              const ThemeSwitcher(),

              const SectionHeader(title: 'Support & Help'),
              ProfileSettingsTile(
                icon: isIOS
                    ? CupertinoIcons.chat_bubble_2
                    : Icons.support_agent,
                title: 'Contact Support',
                subtitle: 'Chat with us on WhatsApp',
                onTap: () => _launchWhatsApp(),
              ),
              ProfileSettingsTile(
                icon: isIOS ? CupertinoIcons.info_circle : Icons.info_outline,
                title: 'About CampusChow',
                onTap: () {
                  // Show about dialog – can be implemented later
                },
              ),

              SizedBox(height: 28.h),
              LogoutButton(auth: auth),
              SizedBox(height: 6.h),
              Center(child: DeleteAccountButton(auth: auth)),
              SizedBox(height: 200.h),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchWhatsApp() async {
    final url = Uri.parse('https://wa.me/2349069211938');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static void _showVerificationModal(
    BuildContext context,
    AuthProvider auth,
    String method,
  ) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => VerificationSheet(auth: auth, method: method),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 6.h), // tightened
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp, // was 11
          fontWeight: FontWeight.w900,
          color: mutedColor.withValues(alpha: 0.6),
          letterSpacing: 1.5,
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}
