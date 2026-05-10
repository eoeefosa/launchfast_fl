import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/features/auth/presentation/widgets/apptextfield.dart';
import 'package:campuschow/store/lib/features/auth/presentation/widgets/auth_prompt.dart';
import 'package:campuschow/store/lib/features/auth/presentation/widgets/custom_button.dart';
import 'package:campuschow/store/lib/features/auth/presentation/widgets/password_toggle.dart';
import 'package:campuschow/store/lib/features/orders/presentation/order_provider.dart';
import 'widgets/constants.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _togglePassword() => setState(() => _showPassword = !_showPassword);

  Future<void> _submitEmailLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _authenticate(
      () => context.read<AuthProvider>().login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      ),
    );
  }

  Future<void> _submitGoogleLogin() async {
    await _authenticate(() => context.read<AuthProvider>().signInWithGoogle());
  }

  Future<void> _authenticate(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final orderProvider = context.read<OrderProvider>();
    final router = GoRouter.of(context);

    try {
      await action();
      orderProvider.refreshOrders();

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isStoreOwner) {
        if (auth.isStoreApproved) {
          router.go('/store');
        } else {
          router.go('/awaiting-approval');
        }
      } else if (auth.user?.role == 'STORE_WORKER') {
        router.go('/worker');
      } else {
        router.go('/store');
        // messenger.showSnackBar(
        //   const SnackBar(
        //     content: Text('Access denied: You do not have store access'),
        //   ),
        // );
        // await auth.logout();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackButton(),
                const SizedBox(height: 32),
                const _LoginHeader(),
                const SizedBox(height: 40),
                _EmailField(controller: _emailCtrl),
                const SizedBox(height: 20),
                _PasswordField(
                  controller: _passwordCtrl,
                  showPassword: _showPassword,
                  onToggle: _togglePassword,
                ),
                const SizedBox(height: 12),
                const ForgotPasswordButton(),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Sign In',
                  isLoading: isLoading,
                  onPressed: _submitEmailLogin,
                  primaryColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                const _OrDivider(),
                const SizedBox(height: 24),
                GoogleSignInButton(
                  isLoading: isLoading,
                  onPressed: _submitGoogleLogin,
                ),
                const SizedBox(height: 40),
                const AuthPrompt(isLogin: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue ordering delicious campus food.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }
}

// ─── Fields ───────────────────────────────────────────────────────────────

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: 'Email',
      icon: Icons.mail_outline,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.email,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.showPassword,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool showPassword;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: 'Password',
      icon: Icons.lock_outline,
      obscureText: !showPassword,
      validator: Validators.password,
      suffixIcon: PasswordToggleIcon(
        isVisible: showPassword,
        onToggle: onToggle,
      ),
    );
  }
}

// ─── OR Divider ───────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }
}
