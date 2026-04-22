import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 40),
              const Text('Store Admin', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Enter your credentials to manage your store', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              _buildInputField(controller: _usernameController, label: 'Username', hint: 'e.g. homeways'),
              const SizedBox(height: 20),
              _buildInputField(controller: _passwordController, label: 'Password', hint: '••••••••', obscure: true),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (authProvider.loginAdmin(_usernameController.text, _passwordController.text)) {
                    context.go('/admin/dashboard');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required String hint, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(hintText: hint, border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey[400])),
          ),
        ),
      ],
    );
  }
}
