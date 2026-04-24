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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() =>
      setState(() => _showPassword = !_showPassword);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await authProvider.register({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
      });

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
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Launch Fast — carefully crafted for your campus needs.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _nameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                  validator: Validators.required('Full name'),
                ),
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
                  controller: _addressController,
                  hint: 'Default Delivery Address',
                  icon: Icons.location_on_outlined,
                  validator: Validators.required('Delivery address'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  hint: 'Phone Number',
                  icon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
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
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Sign Up',
                  isLoading: isLoading,
                  onPressed: _submit,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 32),
                const AuthPrompt(isLogin: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
