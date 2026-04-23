import 'package:flutter/material.dart';
import 'package:launchfast/screens/auth/widgets/constants.dart';
import 'package:launchfast/screens/auth/widgets/custom_button.dart';
import 'package:launchfast/widgets/home/location_selector.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const UnauthenticatedView();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(user: user, auth: auth),
            WalletCard(auth: auth),
            const SizedBox(height: 10),
            LocationSelector(),
            VerificationTile(
              icon: user.emailVerified
                  ? Icons.mark_email_read
                  : Icons.mark_email_unread,
              title: 'Email Verification',
              verified: user.emailVerified,
              onTap: user.emailVerified
                  ? null
                  : () => _showVerificationModal(context, auth, 'email'),
            ),
            VerificationTile(
              icon: user.phoneVerified ? Icons.verified : Icons.phone_android,
              title: 'Phone Verification (Telegram)',
              verified: user.phoneVerified,
              onTap: user.phoneVerified
                  ? null
                  : () => _showVerificationModal(context, auth, 'phone'),
            ),

            _SettingsTile(
              icon: Icons.support_agent,
              title: 'Contact Support',
              onTap: _launchWhatsApp,
            ),
            _LogoutTile(auth: auth),
          ],
        ),
      ),
    );
  }

  // ─── Launchers & Modals ───────────────────────────────────────────────────

  static Future<void> _launchWhatsApp() async {
    final url = Uri.parse('https://wa.me/2349069211938');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  static void _showVerificationModal(
    BuildContext context,
    AuthProvider auth,
    String method,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => VerificationSheet(auth: auth, method: method),
    );
  }
}

// ─── Unauthenticated View ─────────────────────────────────────────────────

class UnauthenticatedView extends StatelessWidget {
  const UnauthenticatedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Please login to view profile',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Go to Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, required this.auth});

  final dynamic user;
  final AuthProvider auth;

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _EditProfileSheet(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                _RoleBadge(role: user.role),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditModal(context),
            icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

// ─── Wallet Card ──────────────────────────────────────────────────────────

class WalletCard extends StatelessWidget {
  const WalletCard({super.key, required this.auth});

  final AuthProvider auth;

  void _showTopUpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _TopUpSheet(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LaunchFast Wallet Balance',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₦${auth.user!.walletBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showTopUpModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Deposit Funds',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Tiles ───────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor ?? Colors.black),
      ),
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: iconColor ?? Colors.grey, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class VerificationTile extends StatelessWidget {
  const VerificationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.verified,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool verified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      title: title,
      iconColor: verified ? Colors.green : Colors.orange,
      titleColor: verified ? null : Colors.orange,
      subtitle: verified ? 'Verified' : 'Tap to verify',
      onTap: onTap,
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.logout,
      title: 'Logout',
      iconColor: Colors.red,
      titleColor: Colors.red,
      onTap: () {
        auth.logout();
        context.read<OrderProvider>().clearOrders();
      },
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.auth});

  final AuthProvider auth;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    final user = widget.auth.user!;
    _nameCtrl = TextEditingController(text: user.name);
    _emailCtrl = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.auth.updateProfile({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    return BottomSheetScaffold(
      title: 'Edit Profile',
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email Address'),
          ),
          const SizedBox(height: 12),
          LocationSelector(),
          const SizedBox(height: 24),
          CustomButton(
            isLoading: widget.auth.isLoading,
            label: 'Save Changes',
            primaryColor: Theme.of(context).primaryColor,
            onPressed: widget.auth.isLoading ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ─── Top-Up Sheet ─────────────────────────────────────────────────────────

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.auth});

  final AuthProvider auth;

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amountCtrl = TextEditingController();

  static const _quickAmounts = [1000, 2000, 5000];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _deposit() {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) return;
    widget.auth.topUpWallet(amt);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('₦${amt.toStringAsFixed(2)} added to wallet!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      title: 'Top Up Wallet',
      child: Column(
        children: [
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(
              labelText: 'Enter Amount (₦)',
              hintText: '0.00',
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: _quickAmounts
                .map(
                  (amt) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _amountCtrl.text = amt.toString()),
                        child: Text('₦$amt'),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          CustomButton(
            isLoading: widget.auth.isLoading,
            label: 'Deposit Now',
            primaryColor: Theme.of(context).primaryColor,
            onPressed: widget.auth.isLoading ? null : _deposit,
          ),
        ],
      ),
    );
  }
}

// ─── Verification Sheet ───────────────────────────────────────────────────

class VerificationSheet extends StatefulWidget {
  const VerificationSheet({
    super.key,
    required this.auth,
    required this.method,
  });

  final AuthProvider auth;
  final String method;

  @override
  State<VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<VerificationSheet> {
  final _otpCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isSending = false;
  bool _codeSent = false;
  bool _isVerifying = false;

  String _predictedNetwork = '';

  bool get _isPhone => widget.method == 'phone';

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_predictNetwork);
  }

  void _predictNetwork() {
    final text = _phoneCtrl.text;
    if (text.length >= 4) {
      final prefix = text.substring(0, 4);
      for (final network in networks) {
        if ((network['prefix'] as List).contains(prefix)) {
          if (_predictedNetwork != network['name']) {
            setState(() {
              _predictedNetwork = network['name'] as String;
            });
          }
          return;
        }
      }
    }
    if (_predictedNetwork.isNotEmpty) {
      setState(() {
        _predictedNetwork = '';
      });
    }
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _isSending = true);
    try {
      await apiService.dio.post(
        '/auth/send-verification',
        data: {
          'method': widget.method,
          if (_isPhone) 'phoneNumber': _phoneCtrl.text.trim(),
        },
      );
      setState(() => _codeSent = true);
    } catch (_) {
      _showSnackBar('Failed to send code. Check details and try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isVerifying = true);
    try {
      await apiService.dio.post(
        '/auth/verify',
        data: {'method': widget.method, 'otp': _otpCtrl.text.trim()},
      );
      await widget.auth.refreshUser();
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Verified successfully!', success: true);
      }
    } catch (_) {
      _showSnackBar(
        'Invalid or expired OTP. Please try again.',
        success: false,
      );
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Color get _networkColor {
    switch (_predictedNetwork) {
      case 'MTN':
        return Colors.yellow.shade100;
      case 'Glo':
        return Colors.green.shade100;
      case 'Airtel':
        return Colors.red.shade100;
      case '9mobile':
        return Colors.orange.shade200;
      default:
        return Colors.white;
    }
  }

  Color get _titleColor {
    switch (_predictedNetwork) {
      case 'MTN':
        return Colors.brown.shade900;
      case 'Glo':
        return Colors.green.shade900;
      case 'Airtel':
        return Colors.red.shade900;
      case '9mobile':
        return Colors.orange.shade900;
      default:
        return Colors.black87;
    }
  }

  Color get _subtitleColor {
    switch (_predictedNetwork) {
      case 'MTN':
        return Colors.brown.shade700;
      case 'Glo':
        return Colors.green.shade700;
      case 'Airtel':
        return Colors.red.shade700;
      case '9mobile':
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isPhone ? 'Verify Phone via Telegram' : 'Verify Email';

    return BottomSheetScaffold(
      title: title,
      backgroundColor: _networkColor,
      textColor: _titleColor,
      child: _codeSent ? _buildOtpStep() : _buildSendStep(context),
    );
  }

  Widget _buildSendStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isPhone) ...[
          Text(
            'To receive your OTP, please enter your Nigerian Phone Number.',
            style: TextStyle(color: _subtitleColor, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(color: _subtitleColor),
              hintText: 'e.g. 0803 123 4567',
              hintStyle: TextStyle(
                color: _subtitleColor.withValues(alpha: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _subtitleColor.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _titleColor, width: 2),
              ),
              suffixIcon: SizedBox(
                width: 60,
                child: Center(
                  child: _predictedNetwork.isNotEmpty
                      ? Text(
                          _predictedNetwork,
                          style: TextStyle(
                            color: _titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 11,
          ),
        ] else
          Text(
            'We will send a 6-digit OTP to ${widget.auth.user!.email}.',
            style: TextStyle(color: _subtitleColor, fontSize: 14),
          ),
        const SizedBox(height: 20),
        CustomButton(
          primaryColor: Theme.of(context).primaryColor,
          label: 'Send Code',
          onPressed: _isSending ? null : _sendCode,
          isLoading: _isSending,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the 6-digit code you received.',
          style: TextStyle(color: _subtitleColor, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otpCtrl,
          style: TextStyle(
            color: _titleColor,
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'OTP Code',
            labelStyle: TextStyle(color: _subtitleColor),
            hintText: '123456',
            hintStyle: TextStyle(color: _subtitleColor.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _subtitleColor.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _titleColor, width: 2),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _otpCtrl,
          builder: (context, value, child) {
            final isValid = value.text.length == 6;
            return CustomButton(
              primaryColor: Theme.of(context).primaryColor,
              isLoading: _isVerifying,
              label: 'Verify Now',
              onPressed: () {
                (_isVerifying || !isValid) ? null : _verifyOtp;
              },
            );
          },
        ),
      ],
    );
  }
}

// ─── Shared Sheet Widgets ─────────────────────────────────────────────────

class BottomSheetScaffold extends StatelessWidget {
  const BottomSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
    this.textColor,
  });

  final String title;
  final Widget child;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
