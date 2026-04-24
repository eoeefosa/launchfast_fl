import 'package:flutter/material.dart';
import '../../../../providers/auth_provider.dart';
import '../../../auth/widgets/custom_button.dart';
import '../../../../widgets/home/location_selector.dart';
import '../widgets/bottom_sheet_scaffold.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.auth});

  final AuthProvider auth;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = widget.auth.user!;
    _nameCtrl = TextEditingController(text: user.name);
    _emailCtrl = TextEditingController(text: user.email);
    _phoneCtrl = TextEditingController(text: user.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.auth.updateProfile({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BottomSheetScaffold(
      title: 'Edit Profile',
      child: Column(
        children: [
          _buildTextField(
            controller: _nameCtrl,
            label: 'Full Name',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          const LocationSelector(),
          const SizedBox(height: 40),
          CustomButton(
            isLoading: widget.auth.isLoading,
            label: 'Save Changes',
            primaryColor: scheme.primary,
            onPressed: widget.auth.isLoading ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        prefixIcon: Icon(icon, color: scheme.primary, size: 20),
      ),
    );
  }
}
