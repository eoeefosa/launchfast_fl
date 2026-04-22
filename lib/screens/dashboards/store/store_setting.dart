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
  // ─── Form Controllers ─────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _deliveryTimeCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();

  // ─── State ────────────────────────────────────────────────────────────────
  String? _storeId;
  List<dynamic> _workers = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingStaff = false;

  @override
  void initState() {
    super.initState();
    _loadStore().then((_) => _loadStaff());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _deliveryTimeCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    super.dispose();
  }

  // ─── Data ─────────────────────────────────────────────────────────────────

  Future<void> _loadStore() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthProvider>().user?.id;
      final res = await apiService.dio.get('/stores');
      final List stores = res.data ?? [];
      if (stores.isEmpty) return;

      final store = stores.firstWhere(
        (s) => s['ownerId'] == userId,
        orElse: () => stores.first,
      );

      _storeId = store['id']?.toString();
      _nameCtrl.text = store['name']?.toString() ?? '';
      _taglineCtrl.text = store['tagline']?.toString() ?? '';
      _deliveryTimeCtrl.text = store['deliveryTime']?.toString() ?? '';
      _deliveryFeeCtrl.text = store['deliveryFee']?.toString() ?? '';
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStaff() async {
    if (_storeId == null) return;
    setState(() => _isLoadingStaff = true);
    try {
      final res = await apiService.dio.get('/stores/$_storeId/staff');
      if (mounted) setState(() => _workers = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingStaff = false);
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
      _showSnackBar('Store updated successfully', success: true);
    } catch (_) {
      _showSnackBar('Failed to save store settings', success: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addStaff(String email) async {
    if (_storeId == null) return;
    try {
      await apiService.dio.post('/stores/$_storeId/staff', data: {'email': email});
      _loadStaff();
      _showSnackBar('Staff added successfully', success: true);
    } catch (_) {
      _showSnackBar('Failed to add staff. Ensure the user exists.', success: false);
    }
  }

  Future<void> _removeStaff(String workerId) async {
    if (_storeId == null) return;
    try {
      await apiService.dio.delete('/stores/$_storeId/staff/$workerId');
      _loadStaff();
    } catch (_) {}
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddStaffDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _AddStaffDialog(
        controller: emailCtrl,
        onAdd: () {
          _addStaff(emailCtrl.text.trim());
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showLogoutDialog() {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (_) => _LogoutDialog(
        onConfirm: () {
          Navigator.pop(context);
          auth.logout();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = _SettingsTheme.of(context);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: _SettingsAppBar(
        isLoading: _isLoading,
        isSaving: _isSaving,
        onSave: _saveStore,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _SettingsBody(
              theme: theme,
              user: user,
              nameCtrl: _nameCtrl,
              taglineCtrl: _taglineCtrl,
              deliveryTimeCtrl: _deliveryTimeCtrl,
              deliveryFeeCtrl: _deliveryFeeCtrl,
              workers: _workers,
              isLoadingStaff: _isLoadingStaff,
              onAddStaff: _showAddStaffDialog,
              onRemoveStaff: _removeStaff,
              onLogout: _showLogoutDialog,
            ),
    );
  }
}

// ─── Theme Helper ─────────────────────────────────────────────────────────

class _SettingsTheme {
  const _SettingsTheme({
    required this.bg,
    required this.surface,
    required this.textColor,
    required this.muted,
    required this.border,
  });

  final Color bg;
  final Color surface;
  final Color textColor;
  final Color muted;
  final Color border;

  static _SettingsTheme of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SettingsTheme(
      bg: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      textColor: isDark ? AppColors.darkText : AppColors.lightText,
      muted: isDark ? AppColors.darkMuted : AppColors.lightMuted,
      border: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────

class _SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SettingsAppBar({
    required this.isLoading,
    required this.isSaving,
    required this.onSave,
  });

  final bool isLoading;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
        if (!isLoading) _SaveButton(isSaving: isSaving, onSave: onSave),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isSaving ? null : onSave,
      child: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.theme,
    required this.user,
    required this.nameCtrl,
    required this.taglineCtrl,
    required this.deliveryTimeCtrl,
    required this.deliveryFeeCtrl,
    required this.workers,
    required this.isLoadingStaff,
    required this.onAddStaff,
    required this.onRemoveStaff,
    required this.onLogout,
  });

  final _SettingsTheme theme;
  final dynamic user;
  final TextEditingController nameCtrl;
  final TextEditingController taglineCtrl;
  final TextEditingController deliveryTimeCtrl;
  final TextEditingController deliveryFeeCtrl;
  final List<dynamic> workers;
  final bool isLoadingStaff;
  final VoidCallback onAddStaff;
  final ValueChanged<String> onRemoveStaff;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCard(user: user, theme: theme),
          const SizedBox(height: 20),
          _SectionLabel('Store Information', theme.textColor),
          const SizedBox(height: 12),
          _StoreFieldsCard(
            theme: theme,
            nameCtrl: nameCtrl,
            taglineCtrl: taglineCtrl,
            deliveryTimeCtrl: deliveryTimeCtrl,
            deliveryFeeCtrl: deliveryFeeCtrl,
          ),
          const SizedBox(height: 24),
          _SectionLabel('Staff Management', theme.textColor),
          const SizedBox(height: 12),
          _StaffCard(
            theme: theme,
            workers: workers,
            isLoading: isLoadingStaff,
            onAdd: onAddStaff,
            onRemove: onRemoveStaff,
          ),
          const SizedBox(height: 24),
          _SectionLabel('Account', theme.textColor),
          const SizedBox(height: 12),
          _SettingsSectionCard(
            theme: theme,
            child: _SettingsTile(
              icon: Icons.logout,
              iconColor: Colors.red,
              label: 'Logout',
              labelColor: Colors.red,
              muted: theme.muted,
              onTap: onLogout,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'LaunchFast v1.0.0',
              style: TextStyle(color: theme.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.theme});

  final dynamic user;
  final _SettingsTheme theme;

  String get _initial =>
      (user?.name?.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'S';

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      theme: theme,
      child: Row(
        children: [
          _AvatarBadge(initial: _initial),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Store Owner',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: theme.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const _RoleBadge(label: 'Store Owner'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Store Fields Card ────────────────────────────────────────────────────

class _StoreFieldsCard extends StatelessWidget {
  const _StoreFieldsCard({
    required this.theme,
    required this.nameCtrl,
    required this.taglineCtrl,
    required this.deliveryTimeCtrl,
    required this.deliveryFeeCtrl,
  });

  final _SettingsTheme theme;
  final TextEditingController nameCtrl;
  final TextEditingController taglineCtrl;
  final TextEditingController deliveryTimeCtrl;
  final TextEditingController deliveryFeeCtrl;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      theme: theme,
      child: Column(
        children: [
          _SettingsInputField(
            label: 'Store Name',
            controller: nameCtrl,
            icon: Icons.store_outlined,
            theme: theme,
          ),
          const SizedBox(height: 14),
          _SettingsInputField(
            label: 'Tagline',
            controller: taglineCtrl,
            icon: Icons.format_quote_outlined,
            theme: theme,
          ),
          const SizedBox(height: 14),
          _SettingsInputField(
            label: 'Delivery Time (e.g. 30-45 min)',
            controller: deliveryTimeCtrl,
            icon: Icons.timer_outlined,
            theme: theme,
          ),
          const SizedBox(height: 14),
          _SettingsInputField(
            label: 'Delivery Fee (₦)',
            controller: deliveryFeeCtrl,
            icon: Icons.local_shipping_outlined,
            theme: theme,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}

// ─── Staff Card ───────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.theme,
    required this.workers,
    required this.isLoading,
    required this.onAdd,
    required this.onRemove,
  });

  final _SettingsTheme theme;
  final List<dynamic> workers;
  final bool isLoading;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (workers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No staff members added yet.',
                style: TextStyle(color: theme.muted, fontSize: 13),
              ),
            )
          else
            ...workers.map(
              (w) => _StaffMemberRow(
                worker: w,
                theme: theme,
                onRemove: () => onRemove(w['id']),
              ),
            ),
          const Divider(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Staff Member'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffMemberRow extends StatelessWidget {
  const _StaffMemberRow({
    required this.worker,
    required this.theme,
    required this.onRemove,
  });

  final dynamic worker;
  final _SettingsTheme theme;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              worker['name'][0].toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker['name'],
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  worker['email'],
                  style: TextStyle(color: theme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.red,
              size: 20,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ─── Shared Section Widgets ───────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.theme,
    required this.child,
  });

  final _SettingsTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsInputField extends StatelessWidget {
  const _SettingsInputField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.theme,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final _SettingsTheme theme;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.textColor),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.muted),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: theme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.muted,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
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

// ─── Dialogs ──────────────────────────────────────────────────────────────

class _AddStaffDialog extends StatelessWidget {
  const _AddStaffDialog({
    required this.controller,
    required this.onAdd,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Staff'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'User Email'),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(onPressed: onAdd, child: const Text('Add')),
      ],
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onConfirm,
          child: const Text('Logout'),
        ),
      ],
    );
  }
}