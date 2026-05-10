import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/features/auth/presentation/widgets/apptextfield.dart';
import 'package:campuschow/store/lib/features/auth/presentation/widgets/auth_prompt.dart';
import 'package:campuschow/store/lib/features/auth/presentation/widgets/custom_button.dart';
import 'package:campuschow/store/lib/features/auth/presentation/widgets/password_toggle.dart';
import 'widgets/constants.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _showPassword = false;
  bool _isGoogleLoggedIn = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() =>
      setState(() => _showPassword = !_showPassword);

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.signInWithGoogle();
      if (!mounted) return;
      if (authProvider.isAuthenticated) {
        if (authProvider.isStoreOwner) {
          context.go('/store');
        } else {
          setState(() {
            _isGoogleLoggedIn = true;
            _nameController.text = authProvider.user?.name ?? '';
          });
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      if (_isGoogleLoggedIn) {
        await authProvider.applyForStore({
          'storeName': _storeNameController.text.trim(),
          'fullName': _nameController.text.trim(),
        });
      } else {
        await authProvider.register({
          'storeName': _storeNameController.text.trim(),
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'storeDescription': _descriptionController.text.trim(),
        });
      }

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isStoreOwner) {
        if (auth.isStoreApproved) {
          router.go('/store');
        } else {
          router.go('/awaiting-approval');
        }
      } else {
        router.go('/profile');
      }
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
                const Text(
                  'Register Your Store',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Lunch Fast — carefully crafted for your campus needs.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _storeNameController,
                  hint: 'Store Name',
                  icon: Icons.store_outlined,
                  validator: Validators.required('Store name'),
                ),
                AppTextField(
                  controller: _nameController,
                  hint: 'User Name (Full Name)',
                  icon: Icons.person_outline,
                  validator: Validators.required('Full name'),
                ),
                if (!_isGoogleLoggedIn) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _descriptionController,
                    hint: 'Store Description (Optional)',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 32),
                CustomButton(
                  label: _isGoogleLoggedIn ? 'Apply for Approval' : 'Register Store',
                  isLoading: isLoading,
                  onPressed: _submit,
                  primaryColor: primaryColor,
                ),
                if (!_isGoogleLoggedIn) ...[
                  const SizedBox(height: 24),
                  const Center(child: Text('OR', style: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 24),
                  GoogleSignInButton(
                    isLoading: isLoading,
                    onPressed: _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 32),
                  const AuthPrompt(isLogin: false),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
