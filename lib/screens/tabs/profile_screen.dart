import 'package:flutter/material.dart';
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
            _ProfileHeader(user: user, auth: auth),
            _WalletCard(auth: auth),
            const SizedBox(height: 10),
            _DeliveryAddressTile(auth: auth),
            _VerificationTile(
              icon: user.emailVerified
                  ? Icons.mark_email_read
                  : Icons.mark_email_unread,
              title: 'Email Verification',
              verified: user.emailVerified,
              onTap: user.emailVerified
                  ? null
                  : () => _showVerificationModal(context, auth, 'email'),
            ),
            _VerificationTile(
              icon: user.phoneVerified ? Icons.verified : Icons.phone_android,
              title: 'Phone Verification (Telegram)',
              verified: user.phoneVerified,
              onTap: user.phoneVerified
                  ? null
                  : () => _showVerificationModal(context, auth, 'phone'),
            ),
            _SettingsTile(
              icon: Icons.credit_card,
              title: 'Payment Methods',
              onTap: _launchWhatsApp,
            ),
            _SettingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _VerificationSheet(auth: auth, method: method),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.auth});

  final dynamic user;
  final AuthProvider auth;

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.auth});

  final AuthProvider auth;

  void _showTopUpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

class _DeliveryAddressTile extends StatelessWidget {
  const _DeliveryAddressTile({required this.auth});

  final AuthProvider auth;

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _EditProfileSheet(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.location_on,
      title: 'Delivery Address',
      onTap: () => _showEditModal(context),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
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
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    final user = widget.auth.user!;
    _nameCtrl = TextEditingController(text: user.name);
    _emailCtrl = TextEditingController(text: user.email);
    _addressCtrl = TextEditingController(text: user.address);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.auth.updateUser({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetScaffold(
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
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Delivery Address'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          _PrimaryButton(label: 'Save Changes', onPressed: _save),
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
    return _BottomSheetScaffold(
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
          _PrimaryButton(label: 'Deposit Now', onPressed: _deposit),
        ],
      ),
    );
  }
}

const _networks = [
  {
    "name": "MTN",
    "prefix": [
      "0803",
      "0703",
      "0903",
      "0806",
      "0706",
      "0813",
      "0810",
      "0814",
      "0816",
      "0906",
      "0913",
      "0916",
      "0910",
      "0702",
    ],
  },
  {
    "name": "Airtel",
    "prefix": [
      "0802",
      "0808",
      "0708",
      "0812",
      "0701",
      "0902",
      "0901",
      "0904",
      "0907",
      "0912",
    ],
  },
  {
    "name": "Glo",
    "prefix": ["0805", "0807", "0705", "0815", "0811", "0905", "0915"],
  },
  {
    "name": "9mobile",
    "prefix": ["0809", "0818", "0817", "0909", "0908"],
  },
];

// ─── Verification Sheet ───────────────────────────────────────────────────

class _VerificationSheet extends StatefulWidget {
  const _VerificationSheet({required this.auth, required this.method});

  final AuthProvider auth;
  final String method;

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
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
      for (final network in _networks) {
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

  @override
  Widget build(BuildContext context) {
    final title = _isPhone ? 'Verify Phone via Telegram' : 'Verify Email';

    return _BottomSheetScaffold(
      title: title,
      child: _codeSent ? _buildOtpStep() : _buildSendStep(context),
    );
  }

  Widget _buildSendStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isPhone) ...[
          const Text(
            'To receive your OTP, please enter your Nigerian Phone Number.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. 0803 123 4567',
              border: const OutlineInputBorder(),
              suffixIcon: _predictedNetwork.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _predictedNetwork,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            keyboardType: TextInputType.phone,
            maxLength: 11,
          ),
        ] else
          Text(
            'We will send a 6-digit OTP to ${widget.auth.user!.email}.',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        const SizedBox(height: 20),
        _PrimaryButton(
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
        const Text(
          'Enter the 6-digit code you received.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otpCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'OTP Code',
            hintText: '123456',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: 'Verify Now',
          onPressed: (_isVerifying || _otpCtrl.text.length != 6)
              ? null
              : _verifyOtp,
          isLoading: _isVerifying,
        ),
      ],
    );
  }
}

// ─── Shared Sheet Widgets ─────────────────────────────────────────────────

class _BottomSheetScaffold extends StatelessWidget {
  const _BottomSheetScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        minimumSize: const Size(double.infinity, 56),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
