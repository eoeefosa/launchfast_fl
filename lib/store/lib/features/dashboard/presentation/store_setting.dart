import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuschow/providers/theme_provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/dashboard/data/staff_member_model.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';
import 'package:campuschow/store/lib/features/dashboard/presentation/staff_provider.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/core/widgets/shimmer_placeholder.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSaving = false;
  bool _isSoundEnabled = true;
  List<_OrderCharge> _charges = [];
  String? _settingsPin; // null = no PIN set

  @override
  void initState() {
    super.initState();
    _loadStore().then((_) {
      if (_storeId != null && mounted) {
        context.read<StaffProvider>().fetchStaff(_storeId!);
      }
    });
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

  Future<void> _loadStore({
    bool showLoading = true,
    bool reloadRemote = false,
  }) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final storeProvider = context.read<StoreProvider>();
      final currentStoreId = _storeId ?? storeProvider.activeStoreId;
      final store = reloadRemote && currentStoreId != null
          ? await storeProvider.reloadStore(currentStoreId)
          : storeProvider.activeStore;
      if (store == null) return;

      if (!mounted) return;
      _storeId = store.id;
      _nameCtrl.text = store.name;
      _taglineCtrl.text = store.tagline;
      _deliveryTimeCtrl.text = store.deliveryTime;
      _deliveryFeeCtrl.text = store.deliveryFee.toInt().toString();

      // Load charges and PIN from the store model (backend-persisted).
      _charges = store.charges
          .map((e) => _OrderCharge.fromJson(e))
          .toList();
      _settingsPin = store.settingsPin;

      // Sound preference is device-local only.
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('order_notifications_sound') ?? true;
    } catch (e) {
      debugPrint('[StoreSettings] _loadStore error: $e');
      _showSnackBar('Failed to load store settings', success: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshStore() async {
    await _loadStore(showLoading: false, reloadRemote: true);
    if (_storeId != null && mounted) {
      await context.read<StaffProvider>().fetchStaff(_storeId!);
    }
  }

  Future<void> _saveStore() async {
    if (_storeId == null) return;

    // If a PIN is set, verify it before allowing the save.
    if (_settingsPin != null && _settingsPin!.isNotEmpty) {
      final ok = await _showPinDialog(mode: _PinMode.verify);
      if (!mounted || ok != true) return;
    }

    setState(() => _isSaving = true);
    try {
      final storeProvider = context.read<StoreProvider>();
      await storeProvider.updateStore(_storeId!, {
        'name': _nameCtrl.text.trim(),
        'description': _taglineCtrl.text.trim(),
        'deliveryTime': _deliveryTimeCtrl.text.trim(),
        'deliveryFee':
            double.tryParse(_deliveryFeeCtrl.text.trim())?.toInt() ?? 0,
        'charges': _charges.map((c) => c.toJson()).toList(),
      });
      if (mounted) {
        _showSnackBar('Store updated successfully', success: true);
      }
    } catch (e) {
      debugPrint('[StoreSettings] _saveStore error: $e');
      if (mounted) {
        _showSnackBar('Failed to save store settings', success: false);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeStaff(String workerId) async {
    if (_storeId == null) return;
    try {
      await context.read<StaffProvider>().removeStaff(_storeId!, workerId);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), success: false);
    }
  }

  // ─── Charges ──────────────────────────────────────────────────────────────

  void _addCharge() => _showChargeDialog(null);
  void _editCharge(int index) => _showChargeDialog(_charges[index], index: index);

  void _removeCharge(int index) {
    setState(() => _charges.removeAt(index));
    // Persist to backend immediately on removal.
    if (_storeId != null) {
      context.read<StoreProvider>().updateStore(_storeId!, {
        'charges': _charges.map((c) => c.toJson()).toList(),
      }).catchError((e) {
        debugPrint('[StoreSettings] _removeCharge persist error: $e');
      });
    }
  }

  void _showChargeDialog(_OrderCharge? existing, {int? index}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.amount.toInt().toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Charge' : 'Edit Charge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Charge name',
                hintText: 'e.g. Packaging fee',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₦)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim());
              if (name.isEmpty || amount == null || amount < 0) return;
              Navigator.pop(ctx);
              setState(() {
                final charge = _OrderCharge(name: name, amount: amount);
                if (index != null) {
                  _charges[index] = charge;
                } else {
                  _charges.add(charge);
                }
              });
              // Persist charges to backend immediately.
              if (_storeId != null) {
                context.read<StoreProvider>().updateStore(_storeId!, {
                  'charges': _charges.map((c) => c.toJson()).toList(),
                }).catchError((e) {
                  debugPrint('[StoreSettings] charge persist error: $e');
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── PIN ──────────────────────────────────────────────────────────────────

  /// Shows PIN entry dialog. Returns true if the entered PIN matches [_settingsPin]
  /// (verify mode) or if the new PIN was saved successfully (set mode).
  Future<bool?> _showPinDialog({required _PinMode mode}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PinDialog(
        mode: mode,
        currentPin: _settingsPin,
        onConfirm: (newPin) async {
          if (mode == _PinMode.set || mode == _PinMode.change) {
            // Persist the new PIN to backend.
            try {
              await context.read<StoreProvider>().updateStore(_storeId!, {
                'settingsPin': newPin,
              });
              if (mounted) setState(() => _settingsPin = newPin);
              return true;
            } catch (e) {
              return false;
            }
          }
          // verify mode — just check equality
          return newPin == _settingsPin;
        },
      ),
    );
  }

  Future<void> _removePin() async {
    if (_storeId == null) return;
    // Ask user to verify current PIN before removing.
    final verified = await _showPinDialog(mode: _PinMode.verify);
    if (!mounted || verified != true) return;
    try {
      await context.read<StoreProvider>().updateStore(_storeId!, {
        'settingsPin': null,
      });
      if (mounted) {
        setState(() => _settingsPin = null);
        _showSnackBar('PIN removed', success: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to remove PIN', success: false);
    }
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
    if (_storeId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _StaffInviteQRDialog(storeId: _storeId!),
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
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAdmin = auth.isAdmin;
    final staffProvider = context.watch<StaffProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: _SettingsAppBar(
        isLoading: _isLoading,
        isRefreshing: _isRefreshing,
        isSaving: _isSaving,
        onSave: _saveStore,
        onRefresh: _refreshStore,
      ),
      body: _isLoading
          ? const _SettingsSkeleton()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshStore,
              child: Stack(
                children: [
                  _SettingsBody(
                    theme: theme,
                    user: user,
                    isAdmin: isAdmin,
                    nameCtrl: _nameCtrl,
                    taglineCtrl: _taglineCtrl,
                    deliveryTimeCtrl: _deliveryTimeCtrl,
                    deliveryFeeCtrl: _deliveryFeeCtrl,
                    workers: staffProvider.staff,
                    isLoadingStaff: staffProvider.isLoading,
                    onAddStaff: _showAddStaffDialog,
                    onRemoveStaff: _removeStaff,
                    themeMode: themeProvider.themeMode,
                    onThemeChanged: themeProvider.setTheme,
                    isSoundEnabled: _isSoundEnabled,
                    onSoundToggle: (val) async {
                      setState(() => _isSoundEnabled = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('order_notifications_sound', val);
                    },
                    charges: _charges,
                    onAddCharge: _addCharge,
                    onEditCharge: _editCharge,
                    onRemoveCharge: _removeCharge,
                    settingsPin: _settingsPin,
                    onSetPin: () => _showPinDialog(
                      mode: _settingsPin == null
                          ? _PinMode.set
                          : _PinMode.change,
                    ),
                    onRemovePin: _removePin,
                    onLogout: _showLogoutDialog,
                  ),
                  if (_isRefreshing)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        color: AppColors.primary,
                        minHeight: 2,
                      ),
                    ),
                ],
              ),
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
    required this.isRefreshing,
    required this.isSaving,
    required this.onSave,
    required this.onRefresh,
  });

  final bool isLoading;
  final bool isRefreshing;
  final bool isSaving;
  final VoidCallback onSave;
  final Future<void> Function() onRefresh;

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
        if (!isLoading)
          IconButton(
            onPressed: isRefreshing || isSaving ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
          ),
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
    required this.isAdmin,
    required this.nameCtrl,
    required this.taglineCtrl,
    required this.deliveryTimeCtrl,
    required this.deliveryFeeCtrl,
    required this.workers,
    required this.isLoadingStaff,
    required this.onAddStaff,
    required this.onRemoveStaff,
    required this.themeMode,
    required this.onThemeChanged,
    required this.isSoundEnabled,
    required this.onSoundToggle,
    required this.charges,
    required this.onAddCharge,
    required this.onEditCharge,
    required this.onRemoveCharge,
    required this.settingsPin,
    required this.onSetPin,
    required this.onRemovePin,
    required this.onLogout,
  });

  final _SettingsTheme theme;
  final dynamic user;
  final bool isAdmin;
  final TextEditingController nameCtrl;
  final TextEditingController taglineCtrl;
  final TextEditingController deliveryTimeCtrl;
  final TextEditingController deliveryFeeCtrl;
  final List<StaffMember> workers;
  final bool isLoadingStaff;
  final VoidCallback onAddStaff;
  final ValueChanged<String> onRemoveStaff;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final bool isSoundEnabled;
  final ValueChanged<bool> onSoundToggle;
  final List<_OrderCharge> charges;
  final VoidCallback onAddCharge;
  final ValueChanged<int> onEditCharge;
  final ValueChanged<int> onRemoveCharge;
  final String? settingsPin;
  final VoidCallback onSetPin;
  final VoidCallback onRemovePin;
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
          _SectionLabel('Order Charges', theme.textColor),
          const SizedBox(height: 4),
          Text(
            'Extra charges applied on every order. Customers see these at checkout.',
            style: TextStyle(color: theme.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _OrderChargesCard(
            theme: theme,
            charges: charges,
            onAdd: onAddCharge,
            onEdit: onEditCharge,
            onRemove: onRemoveCharge,
          ),
          const SizedBox(height: 24),
          _SectionLabel('Appearance', theme.textColor),
          const SizedBox(height: 12),
          _ThemeSettingsCard(
            theme: theme,
            themeMode: themeMode,
            onChanged: onThemeChanged,
          ),
          const SizedBox(height: 24),
          _SectionLabel('Notifications', theme.textColor),
          const SizedBox(height: 12),
          _NotificationSettingsCard(
            theme: theme,
            isEnabled: isSoundEnabled,
            onChanged: onSoundToggle,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 24),
            _SectionLabel('Security', theme.textColor),
            const SizedBox(height: 4),
            Text(
              'Settings PIN protects store settings from unauthorised changes. Only admins can set or change it.',
              style: TextStyle(color: theme.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _PinSettingsCard(
              theme: theme,
              hasPin: settingsPin != null && settingsPin!.isNotEmpty,
              onSetPin: onSetPin,
              onRemovePin: onRemovePin,
            ),
          ],
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
              'Store Launchfast v1.0.0',
              style: TextStyle(color: theme.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ThemeSettingsCard extends StatelessWidget {
  const _ThemeSettingsCard({
    required this.theme,
    required this.themeMode,
    required this.onChanged,
  });

  final _SettingsTheme theme;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  bool get _isLight => themeMode == ThemeMode.light;
  bool get _isDark => themeMode == ThemeMode.dark;
  bool get _isSystem => themeMode == ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Mode',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _isDark
                          ? 'Dark mode enabled'
                          : _isLight
                          ? 'Light mode enabled'
                          : 'Follow system setting',
                      style: TextStyle(color: theme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _ThemeModeButton(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: _isLight,
                  onTap: () => onChanged(ThemeMode.light),
                ),
                _ThemeModeButton(
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  selected: _isSystem,
                  onTap: () => onChanged(ThemeMode.system),
                ),
                _ThemeModeButton(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: _isDark,
                  onTap: () => onChanged(ThemeMode.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}


class _NotificationSettingsCard extends StatelessWidget {
  const _NotificationSettingsCard({
    required this.theme,
    required this.isEnabled,
    required this.onChanged,
  });

  final _SettingsTheme theme;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      theme: theme,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Order Sound',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Play alert sound when a new order arrives',
                  style: TextStyle(color: theme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
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
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.theme, required this.child});

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

class _StaffInviteQRDialog extends StatelessWidget {
  const _StaffInviteQRDialog({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Staff', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Show this QR code to your staff members to join this store.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: 'launchfast://store/invite?storeId=$storeId',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog({required this.onConfirm, required this.onCancel});

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


// ─── PIN Mode Enum ────────────────────────────────────────────────────────

enum _PinMode { verify, set, change }

// ─── PIN Settings Card ────────────────────────────────────────────────────

class _PinSettingsCard extends StatelessWidget {
  const _PinSettingsCard({
    required this.theme,
    required this.hasPin,
    required this.onSetPin,
    required this.onRemovePin,
  });

  final _SettingsTheme theme;
  final bool hasPin;
  final VoidCallback onSetPin;
  final VoidCallback onRemovePin;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      theme: theme,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings PIN',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      hasPin ? 'PIN is set — required to save changes' : 'No PIN set',
                      style: TextStyle(color: theme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasPin
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasPin ? 'Active' : 'Off',
                  style: TextStyle(
                    color: hasPin ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(hasPin ? Icons.edit_rounded : Icons.add_rounded,
                      size: 16),
                  label: Text(hasPin ? 'Change PIN' : 'Set PIN'),
                  onPressed: onSetPin,
                ),
              ),
              if (hasPin) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text('Remove PIN'),
                    onPressed: onRemovePin,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PIN Dialog ───────────────────────────────────────────────────────────

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.mode,
    required this.currentPin,
    required this.onConfirm,
  });

  final _PinMode mode;
  final String? currentPin;
  final Future<bool> Function(String pin) onConfirm;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  String get _title => switch (widget.mode) {
        _PinMode.verify => 'Enter Settings PIN',
        _PinMode.set => 'Set Settings PIN',
        _PinMode.change => 'Change Settings PIN',
      };

  bool get _needsConfirm =>
      widget.mode == _PinMode.set || widget.mode == _PinMode.change;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _error = 'PIN must be exactly 4 digits');
      return;
    }
    if (_needsConfirm && _confirmCtrl.text.trim() != pin) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final ok = await widget.onConfirm(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = widget.mode == _PinMode.verify
            ? 'Incorrect PIN'
            : 'Failed to save PIN. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.mode == _PinMode.verify)
            const Text(
              'Enter the 4-digit PIN to continue.',
              style: TextStyle(fontSize: 13),
            )
          else
            const Text(
              'Choose a 4-digit numeric PIN.',
              style: TextStyle(fontSize: 13),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: _obscure,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: widget.mode == _PinMode.verify ? 'PIN' : 'New PIN',
              counterText: '',
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _needsConfirm ? null : _submit(),
          ),
          if (_needsConfirm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              keyboardType: TextInputType.number,
              obscureText: _obscure,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}

// ─── Order Charge Model ───────────────────────────────────────────────────

class _OrderCharge {
  final String name;
  final double amount;

  const _OrderCharge({required this.name, required this.amount});

  factory _OrderCharge.fromJson(Map<String, dynamic> json) => _OrderCharge(
        name: json['name']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

// ─── Order Charges Card ───────────────────────────────────────────────────

class _OrderChargesCard extends StatelessWidget {
  const _OrderChargesCard({
    required this.theme,
    required this.charges,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final _SettingsTheme theme;
  final List<_OrderCharge> charges;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  double get _total => charges.fold(0, (s, c) => s + c.amount);

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (charges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No charges added yet.',
                style: TextStyle(color: theme.muted, fontSize: 13),
              ),
            )
          else ...[
            ...List.generate(charges.length, (i) {
              final c = charges[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.name,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '₦${c.amount.toInt()}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: theme.muted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => onEdit(i),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => onRemove(i),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total per order',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '₦${_total.toInt()}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Divider(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Charge'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    Widget card(List<Widget> children) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Store image placeholder
          Center(child: ShimmerPlaceholder(width: 100, height: 100, borderRadius: 50)),
          const SizedBox(height: 24),
          card([
            ShimmerPlaceholder(width: 100, height: 12, borderRadius: 6),
            const SizedBox(height: 8),
            ShimmerPlaceholder(width: double.infinity, height: 44, borderRadius: 12),
            const SizedBox(height: 16),
            ShimmerPlaceholder(width: 100, height: 12, borderRadius: 6),
            const SizedBox(height: 8),
            ShimmerPlaceholder(width: double.infinity, height: 44, borderRadius: 12),
          ]),
          card([
            ShimmerPlaceholder(width: 120, height: 12, borderRadius: 6),
            const SizedBox(height: 8),
            ShimmerPlaceholder(width: double.infinity, height: 44, borderRadius: 12),
            const SizedBox(height: 16),
            ShimmerPlaceholder(width: 100, height: 12, borderRadius: 6),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ShimmerPlaceholder(width: double.infinity, height: 44, borderRadius: 12)),
              const SizedBox(width: 12),
              Expanded(child: ShimmerPlaceholder(width: double.infinity, height: 44, borderRadius: 12)),
            ]),
          ]),
          card([
            ShimmerPlaceholder(width: 80, height: 12, borderRadius: 6),
            const SizedBox(height: 8),
            ShimmerPlaceholder(width: double.infinity, height: 44, borderRadius: 12),
          ]),
        ],
      ),
    );
  }
}
