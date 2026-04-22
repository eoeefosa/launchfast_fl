import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launchfast_fl/constants/app_colors.dart';
import 'package:launchfast_fl/providers/auth_provider.dart';
import 'package:launchfast_fl/services/api_service.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  Map<String, dynamic>? _storeData;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _deliveryTimeCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  String? _storeId;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id;
      final res = await apiService.dio.get('/stores');
      final List stores = res.data ?? [];
      if (stores.isNotEmpty) {
        final storeMap = stores.firstWhere(
          (s) => s['ownerId'] == userId,
          orElse: () => stores.first,
        );
        _storeData = storeMap;
        _storeId = storeMap['id']?.toString();
        _nameCtrl.text = storeMap['name']?.toString() ?? '';
        _taglineCtrl.text = storeMap['tagline']?.toString() ?? '';
        _deliveryTimeCtrl.text = storeMap['deliveryTime']?.toString() ?? '';
        _deliveryFeeCtrl.text = storeMap['deliveryFee']?.toString() ?? '';
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveStore() async {
    if (_storeId == null) return;
    setState(() => _isSaving = true);
    try {
      await apiService.dio.put('/stores/$_storeId', data: {
        'name': _nameCtrl.text.trim(),
        'tagline': _taglineCtrl.text.trim(),
        'deliveryTime': _deliveryTimeCtrl.text.trim(),
        'deliveryFee': double.tryParse(_deliveryFeeCtrl.text.trim()) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Store updated successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to save store settings'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _deliveryTimeCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveStore,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile Card ──
                  _sectionCard(
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFFFF9A5C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              (user?.name.isNotEmpty == true)
                                  ? user!.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Store Owner',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(color: muted, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Store Owner',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    surface: surface,
                    border: border,
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle('Store Information', textColor),
                  const SizedBox(height: 12),

                  // ── Store Fields ──
                  _sectionCard(
                    child: Column(
                      children: [
                        _inputField(
                          label: 'Store Name',
                          ctrl: _nameCtrl,
                          icon: Icons.store_outlined,
                          textColor: textColor,
                          muted: muted,
                          border: border,
                          surface: surface,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          label: 'Tagline',
                          ctrl: _taglineCtrl,
                          icon: Icons.format_quote_outlined,
                          textColor: textColor,
                          muted: muted,
                          border: border,
                          surface: surface,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          label: 'Delivery Time (e.g. 30-45 min)',
                          ctrl: _deliveryTimeCtrl,
                          icon: Icons.timer_outlined,
                          textColor: textColor,
                          muted: muted,
                          border: border,
                          surface: surface,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          label: 'Delivery Fee (₦)',
                          ctrl: _deliveryFeeCtrl,
                          icon: Icons.local_shipping_outlined,
                          keyboardType: TextInputType.number,
                          textColor: textColor,
                          muted: muted,
                          border: border,
                          surface: surface,
                        ),
                      ],
                    ),
                    surface: surface,
                    border: border,
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle('Account', textColor),
                  const SizedBox(height: 12),

                  // ── Logout ──
                  _sectionCard(
                    child: _settingsTile(
                      icon: Icons.logout,
                      iconColor: Colors.red,
                      label: 'Logout',
                      labelColor: Colors.red,
                      textColor: textColor,
                      muted: muted,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text(
                                'Are you sure you want to logout?'),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  auth.logout();
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    surface: surface,
                    border: border,
                  ),

                  const SizedBox(height: 40),

                  // ── App Version ──
                  Center(
                    child: Text(
                      'LaunchFast v1.0.0',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    required Color surface,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    required Color textColor,
    required Color muted,
    required Color border,
    required Color surface,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: textColor),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: muted),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required Color textColor,
    required Color muted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 14, color: muted),
        ],
      ),
    );
  }
}