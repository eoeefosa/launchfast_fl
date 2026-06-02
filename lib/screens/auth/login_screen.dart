import 'package:flutter/material.dart';
import 'package:campuschow/screens/auth/widgets/apptextfield.dart';
import 'package:campuschow/screens/auth/widgets/auth_prompt.dart';
import 'package:campuschow/screens/auth/widgets/constants.dart';
import 'package:campuschow/screens/auth/widgets/custom_button.dart';
import 'package:campuschow/screens/auth/widgets/password_toggle.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/responsive_layout.dart';

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
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    try {
      await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    if (mounted && auth.isAuthenticated) {
      context.go(_postAuthRoute(auth));
    }
  }

  Future<void> _submitGoogleLogin() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    if (mounted && auth.isAuthenticated) {
      context.go(_postAuthRoute(auth));
    }
  }

  Future<void> _submitAppleLogin() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.signInWithApple();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    if (mounted && auth.isAuthenticated) {
      context.go(_postAuthRoute(auth));
    }
  }

  String _postAuthRoute(AuthProvider auth) {
    if (auth.isAdmin || auth.isStoreOwner) return '/dashboard';
    if (auth.isWorker) return '/worker';
    return '/profile';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ResponsiveLayout(
      child: Scaffold(
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                      Expanded(
                        child: Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// Google login
                  GoogleSignInButton(
                    isLoading: isLoading,
                    onPressed: _submitGoogleLogin,
                  ),

                  if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 12),
                    AppleSignInButton(
                      isLoading: isLoading,
                      onPressed: _submitAppleLogin,
                    ),
                  ],

                  const SizedBox(height: 40),

                  /// Signup prompt
                  const AuthPrompt(isLogin: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
