import 'package:flutter/material.dart';
import 'package:launchfast/screens/auth/widgets/apptextfield.dart';
import 'package:launchfast/screens/auth/widgets/auth_prompt.dart';
import 'package:launchfast/screens/auth/widgets/constants.dart';
import 'package:launchfast/screens/auth/widgets/custom_button.dart';
import 'package:launchfast/screens/auth/widgets/password_toggle.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);
    final primaryColor = Theme.of(context).primaryColor;

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

                /// Header
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue ordering delicious campus food.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                /// Email
                AppTextField(
                  controller: _emailController,
                  hint: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),

                const SizedBox(height: 20),

                /// Password
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

                /// Forgot password
                const ForgotPasswordButton(),

                const SizedBox(height: 20),

                /// Login button
                CustomButton(
                  label: 'Sign In',
                  isLoading: isLoading,
                  onPressed: _submitEmailLogin,
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 24),

                /// Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.5))),
                  ],
                ),

                const SizedBox(height: 24),

                /// Google login
                GoogleSignInButton(
                  isLoading: isLoading,
                  onPressed: _submitGoogleLogin,
                ),

                const SizedBox(height: 40),

                /// Signup prompt
                const AuthPrompt(isLogin: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
