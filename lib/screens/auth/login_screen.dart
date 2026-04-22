import 'package:flutter/material.dart';
import 'package:launchfast_fl/screens/auth/widgets/apptextfield.dart';
import 'package:launchfast_fl/screens/auth/widgets/auth_prompt.dart';
import 'package:launchfast_fl/screens/auth/widgets/constants.dart';
import 'package:launchfast_fl/screens/auth/widgets/custom_button.dart';
import 'package:launchfast_fl/screens/auth/widgets/password_toggle.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: _LoginForm(),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _togglePasswordVisibility() =>
      setState(() => _showPassword = !_showPassword);

  Future<void> _submitEmailLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _authenticate(
      () => context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  Future<void> _submitGoogleLogin() async {
    await _authenticate(() => context.read<AuthProvider>().signInWithGoogle());
  }

  /// Shared auth flow: runs [action], then navigates or shows an error.
  /// Context-dependent objects are captured before the await.
  Future<void> _authenticate(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final orderProvider = context.read<OrderProvider>();
    final router = GoRouter.of(context);

    try {
      await action();
      orderProvider.refreshOrders();
      router.go('/');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);
    final primaryColor = Theme.of(context).primaryColor;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackButton(),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue ordering delicious campus food.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          AppTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscureText: !_showPassword,
            validator: Validators.password,
            suffixIcon: PasswordToggleIcon(
              isVisible: _showPassword,
              onToggle: _togglePasswordVisibility,
            ),
          ),
          const SizedBox(height: 12),
          const _ForgotPasswordButton(),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: _submitEmailLogin,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 24),
          const _OrDivider(),
          const SizedBox(height: 24),
          _GoogleSignInButton(
            isLoading: isLoading,
            onPressed: _submitGoogleLogin,
          ),
          const SizedBox(height: 40),
          const AuthPrompt(isLogin: true),
        ],
      ),
    );
  }
}

class _ForgotPasswordButton extends StatelessWidget {
  const _ForgotPasswordButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: navigate to forgot-password screen
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

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

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.g_mobiledata, size: 30),
                SizedBox(width: 12),
                Text(
                  'Sign in with Google',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
