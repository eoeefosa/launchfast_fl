import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/home/location_selector.dart';

// Broken down components
import 'profile/widgets/profile_header.dart';
import 'profile/widgets/wallet_card.dart';
import 'profile/widgets/settings_tile.dart';
import 'profile/widgets/verification_tile.dart';

import 'profile/widgets/unauthenticated_view.dart';
import 'profile/sheets/verification_sheet.dart';

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

              const _SectionHeader(title: 'Account Verification'),
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

              const _SectionHeader(title: 'Preferences'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: LocationSelector(),
              ),
              _ThemeSwitcher(),

              const _SectionHeader(title: 'Support & Help'),
              ProfileSettingsTile(
                icon: isIOS
                    ? CupertinoIcons.chat_bubble_2
                    : Icons.support_agent,
                title: 'Contact Support',
                subtitle: 'Chat with us on WhatsApp',
                onTap: _launchWhatsApp,
              ),
              ProfileSettingsTile(
                icon: isIOS ? CupertinoIcons.info_circle : Icons.info_outline,
                title: 'About LaunchFast',
                onTap: () {
                  // Show about dialog
                },
              ),

              const SizedBox(height: 32),
              _LogoutButton(auth: auth),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.auth});
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: () {
          HapticFeedback.heavyImpact();
          _showLogoutDialog(context);
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  void _showLogoutDialog(BuildContext context) {
    final isIOS = Platform.isIOS;
    if (isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out of your account?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Sign Out'),
              onPressed: () {
                Navigator.pop(context);
                auth.logout();
                context.read<OrderProvider>().clearOrders();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                auth.logout();
                context.read<OrderProvider>().clearOrders();
              },
              child: const Text(
                'SIGN OUT',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ── Theme Switcher ────────────────────────────────────────────────────────────

class _ThemeSwitcher extends StatelessWidget {
  const _ThemeSwitcher();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 4),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDark
                        ? Icons.dark_mode_rounded
                        : themeProvider.isLight
                        ? Icons.light_mode_rounded
                        : Icons.brightness_auto_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        themeProvider.isDark
                            ? 'Dark Mode'
                            : themeProvider.isLight
                            ? 'Light Mode'
                            : 'System Default',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _ThemeOption(
                    label: 'Light',
                    icon: Icons.light_mode_rounded,
                    selected: themeProvider.isLight,
                    onTap: () => themeProvider.setTheme(ThemeMode.light),
                  ),
                  _ThemeOption(
                    label: 'System',
                    icon: Icons.brightness_auto_rounded,
                    selected: themeProvider.isSystem,
                    onTap: () => themeProvider.setTheme(ThemeMode.system),
                  ),
                  _ThemeOption(
                    label: 'Dark',
                    icon: Icons.dark_mode_rounded,
                    selected: themeProvider.isDark,
                    onTap: () => themeProvider.setTheme(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
