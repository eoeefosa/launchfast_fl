import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:campuschow/screens/tabs/profile/widgets/logout_button.dart';
import 'package:campuschow/screens/tabs/profile/widgets/theme_switcher.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/home/location_selector.dart';

// Broken down components
import 'widgets/profile_header.dart';
import 'widgets/wallet_card.dart';
import 'widgets/settings_tile.dart';
import 'widgets/verification_tile.dart';

import 'widgets/unauthenticated_view.dart';
import 'sheets/verification_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const UnauthenticatedView();

    final isIOS = Platform.isIOS;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        centerTitle: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1,
          ),
        ),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => auth.refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(user: user, auth: auth),

              WalletCard(auth: auth),

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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: LocationSelector(),
              ),
              ThemeSwitcher(),

              const SectionHeader(title: 'Support & Help'),
              ProfileSettingsTile(
                icon: isIOS
                    ? CupertinoIcons.chat_bubble_2
                    : Icons.support_agent,
                title: 'Contact Support',
                subtitle: 'Chat with us on WhatsApp',
                onTap: () {
                  _launchWhatsApp;
                },
              ),
              ProfileSettingsTile(
                icon: isIOS ? CupertinoIcons.info_circle : Icons.info_outline,
                title: 'About CampusChow',
                onTap: () {
                  // Show about dialog
                },
              ),

              const SizedBox(height: 32),
              LogoutButton(auth: auth),
              const SizedBox(height: 200),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerificationSheet(auth: auth, method: method),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}
