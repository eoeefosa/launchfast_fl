import 'package:flutter/material.dart';
import 'package:launchfast/constants/app_colors.dart';
import 'package:launchfast/services/api_service.dart';

// ─── Main Widget ──────────────────────────────────────────────────────────────

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterRole = 'ALL';

  static const _roles = [
    'ALL',
    'CUSTOMER',
    'STORE_OWNER',
    'STORE_WORKER',
    'RIDER',
    'SUPER_ADMIN',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ─── Data ─────────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    await Future.wait([_loadUsers(), _loadStores()]);
  }

  Future<void> _loadUsers() async {
    try {
      final res = await apiService.dio.get('/admin/users');
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(res.data ?? []);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStores() async {
    try {
      final res = await apiService.dio.get('/admin/stores');
      if (mounted) {
        setState(
          () => _stores = List<Map<String, dynamic>>.from(res.data ?? []),
        );
      }
    } catch (_) {}
  }

  // ─── Role Update ──────────────────────────────────────────────────────────

  Future<void> _updateRole(Map<String, dynamic> user, String newRole) async {
    // If STORE_OWNER, show the store-picker dialog first
    if (newRole == 'STORE_OWNER') {
      final storeId = await _pickStore(user);
      if (storeId == null) return; // cancelled
      await _patchRole(user['id'] as String, newRole, storeId: storeId);
    } else {
      await _patchRole(user['id'] as String, newRole);
    }
  }

  Future<void> _patchRole(
    String userId,
    String newRole, {
    String? storeId,
  }) async {
    try {
      await apiService.dio.patch(
        '/admin/users/$userId/role',
        data: {'role': newRole, 'storeId': storeId},
      );

      // Optimistically update local list
      setState(() {
        final idx = _users.indexWhere((u) => u['id'] == userId);
        if (idx != -1) _users[idx] = {..._users[idx], 'role': newRole};
      });

      if (!mounted) return;
      _showSnack(
        '✅ Role updated to ${_roleLabel(newRole)} — user will be re-routed instantly',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('❌ Failed to update role. Try again.', success: false);
    }
  }

  // ─── Store Picker ─────────────────────────────────────────────────────────

  Future<String?> _pickStore(Map<String, dynamic> user) async {
    if (_stores.isEmpty) {
      _showSnack('No stores available to assign.', success: false);
      return null;
    }
    return showDialog<String>(
      context: context,
      builder: (ctx) => _StorePickerDialog(
        stores: _stores,
        userName: user['name'] as String? ?? 'user',
      ),
    );
  }

  // ─── Filters ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((u) {
      final role = u['role'] as String? ?? '';
      final name = (u['name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesRole = _filterRole == 'ALL' || role == _filterRole;
      final matchesSearch = q.isEmpty || name.contains(q) || email.contains(q);

      return matchesRole && matchesSearch;
    }).toList();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static String _roleLabel(String role) => role
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      })
      .join(' ');

  static Color _roleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return Colors.red.shade400;
      case 'STORE_OWNER':
        return Colors.green.shade500;
      case 'STORE_WORKER':
        return Colors.orange.shade400;
      case 'RIDER':
        return Colors.blue.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _SearchBar(
            onChanged: (q) => setState(() => _searchQuery = q),
            surface: surface,
            border: border,
            muted: muted,
          ),
          _RoleFilterChips(
            roles: _roles,
            selected: _filterRole,
            onSelect: (r) => setState(() => _filterRole = r),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filtered.isEmpty
                ? _EmptyState(muted: muted)
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _UserCard(
                        user: filtered[i],
                        isDark: isDark,
                        textColor: textColor,
                        border: border,
                        surface: surface,
                        roleColor: _roleColor(
                          filtered[i]['role'] as String? ?? '',
                        ),
                        roleLabel: _roleLabel(
                          filtered[i]['role'] as String? ?? '',
                        ),
                        onRoleChange: (newRole) =>
                            _updateRole(filtered[i], newRole),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: AppColors.primary,
    elevation: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          '${_users.length} users · live via Ably',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _loadAll,
        tooltip: 'Refresh',
      ),
    ],
  );
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.onChanged,
    required this.surface,
    required this.border,
    required this.muted,
  });

  final ValueChanged<String> onChanged;
  final Color surface;
  final Color border;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or email…',
          hintStyle: TextStyle(color: muted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: muted, size: 20),
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }
}

// ─── Role Filter Chips ────────────────────────────────────────────────────────

class _RoleFilterChips extends StatelessWidget {
  const _RoleFilterChips({
    required this.roles,
    required this.selected,
    required this.onSelect,
  });

  final List<String> roles;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: roles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final role = roles[i];
          final isSelected = selected == role;
          final label = role == 'ALL'
              ? 'All'
              : role
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((w) {
                      if (w.isEmpty) return w;
                      return w[0] + w.substring(1).toLowerCase();
                    })
                    .join(' ');

          return GestureDetector(
            onTap: () => onSelect(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isDark,
    required this.textColor,
    required this.border,
    required this.surface,
    required this.roleColor,
    required this.roleLabel,
    required this.onRoleChange,
  });

  final Map<String, dynamic> user;
  final bool isDark;
  final Color textColor;
  final Color border;
  final Color surface;
  final Color roleColor;
  final String roleLabel;
  final ValueChanged<String> onRoleChange;

  String get _initial => (user['name'] as String? ?? '?').isNotEmpty
      ? (user['name'] as String)[0].toUpperCase()
      : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Text(
            _initial,
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          user['name'] as String? ?? 'Unknown',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user['email'] as String? ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 6),
            _RoleBadge(label: roleLabel, color: roleColor),
          ],
        ),
        trailing: _RoleMenu(onSelect: onRoleChange),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _RoleMenu extends StatelessWidget {
  const _RoleMenu({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: onSelect,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        _menuItem('CUSTOMER', Icons.person_outline, Colors.grey),
        _menuItem('STORE_OWNER', Icons.store_outlined, Colors.green),
        _menuItem('STORE_WORKER', Icons.people_outline, Colors.orange),
        _menuItem('RIDER', Icons.delivery_dining_outlined, Colors.blue),
        _menuItem(
          'SUPER_ADMIN',
          Icons.admin_panel_settings_outlined,
          Colors.red,
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, Color color) {
    final label = value
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0] + w.substring(1).toLowerCase();
        })
        .join(' ');

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Store Picker Dialog ──────────────────────────────────────────────────────

class _StorePickerDialog extends StatefulWidget {
  const _StorePickerDialog({required this.stores, required this.userName});

  final List<Map<String, dynamic>> stores;
  final String userName;

  @override
  State<_StorePickerDialog> createState() => _StorePickerDialogState();
}

class _StorePickerDialogState extends State<_StorePickerDialog> {
  String? _selectedStoreId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assign Store',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a store to assign to ${widget.userName}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.stores.length,
          itemBuilder: (_, i) {
            final store = widget.stores[i];
            final storeId = store['id'] as String;
            final storeName = store['name'] as String? ?? 'Unknown Store';
            final isOwned = store['ownerId'] != null;
            final isSelected = _selectedStoreId == storeId;

            return GestureDetector(
              onTap: () => setState(() => _selectedStoreId = storeId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.black87,
                            ),
                          ),
                          if (isOwned)
                            const Text(
                              'Already has an owner',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedStoreId == null
              ? null
              : () => Navigator.pop(context, _selectedStoreId),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.muted});

  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: muted),
          const SizedBox(height: 12),
          Text(
            'No users match your filters.',
            style: TextStyle(color: muted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
