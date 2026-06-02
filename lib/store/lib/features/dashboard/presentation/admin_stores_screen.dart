import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/network/api_client.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/store/data/store_model.dart';
import 'package:dio/dio.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  List<Store> _stores = [];
  List<Store> _filtered = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    setState(() => _isLoading = true);
    try {
      final response = await apiService.dio.get('/admin/stores');
      final stores = (response.data as List)
          .map((s) => Store.fromJson(s as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _applyFilter();
      });
    } catch (e) {
      _showSnack('Failed to load stores: $e', success: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_stores)
        : _stores
            .where((s) => s.name.toLowerCase().contains(q))
            .toList();
  }

  Future<void> _patch(String storeId, Map<String, dynamic> data) async {
    try {
      final response = await apiService.dio.patch(
        '/admin/stores',
        data: {'storeId': storeId, ...data},
      );
      final updated = Store.fromJson(response.data['store'] as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        final idx = _stores.indexWhere((s) => s.id == storeId);
        if (idx != -1) _stores[idx] = updated;
        _applyFilter();
      });
      _showSnack('Updated', success: true);
    } on DioException catch (e) {
      _showSnack(
        e.response?.data?['error'] ?? 'Update failed',
        success: false,
      );
    }
  }

  void _showSnack(String msg, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _editDeliveryFee(Store store) {
    final ctrl = TextEditingController(text: store.deliveryFee.toInt().toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Delivery Fee — ${store.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Delivery Fee (₦)',
            prefixIcon: Icon(Icons.local_shipping_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              if (val == null) return;
              Navigator.pop(context);
              _patch(store.id, {'deliveryFee': val.toInt()});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editDeliveryTime(Store store) {
    final ctrl = TextEditingController(text: store.deliveryTime);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Delivery Time — ${store.name}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Delivery Time (e.g. 30-45 min)',
            prefixIcon: Icon(Icons.timer_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              Navigator.pop(context);
              _patch(store.id, {'deliveryTime': val});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Manage Stores',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchStores,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() {
                _search = v;
                _applyFilter();
              }),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search stores...',
                hintStyle: TextStyle(color: muted),
                prefixIcon: Icon(Icons.search, color: muted),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
          ),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} store${_filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No stores found',
                          style: TextStyle(color: muted),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetchStores,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final store = _filtered[i];
                            return _StoreCard(
                              store: store,
                              surface: surface,
                              textColor: textColor,
                              muted: muted,
                              border: border,
                              onEditFee: () => _editDeliveryFee(store),
                              onEditTime: () => _editDeliveryTime(store),
                              onToggleOpen: (val) =>
                                  _patch(store.id, {'isOpen': val}),
                              onToggleApproved: (val) =>
                                  _patch(store.id, {'isApproved': val}),
                            );
                          },
                        ),
                      ),
          ),

          // Footer note
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Platform adds ₦300 on top of each store\'s delivery fee for delivery orders',
              style: TextStyle(color: muted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.surface,
    required this.textColor,
    required this.muted,
    required this.border,
    required this.onEditFee,
    required this.onEditTime,
    required this.onToggleOpen,
    required this.onToggleApproved,
  });

  final Store store;
  final Color surface;
  final Color textColor;
  final Color muted;
  final Color border;
  final VoidCallback onEditFee;
  final VoidCallback onEditTime;
  final ValueChanged<bool> onToggleOpen;
  final ValueChanged<bool> onToggleApproved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _parseColor(store.accentColor)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: _parseColor(store.accentColor),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      store.tagline.isEmpty ? 'No tagline' : store.tagline,
                      style: TextStyle(color: muted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Approved badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: store.isApproved
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  store.isApproved ? 'Approved' : 'Pending',
                  style: TextStyle(
                    color: store.isApproved ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Editable fields row
          Row(
            children: [
              // Delivery fee
              Expanded(
                child: GestureDetector(
                  onTap: onEditFee,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Fee',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '₦${store.deliveryFee.toInt()}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.edit,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delivery time
              Expanded(
                child: GestureDetector(
                  onTap: onEditTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Time',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                store.deliveryTime,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.edit,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Toggle row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      store.isOpen
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 16,
                      color: store.isOpen ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      store.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: store.isOpen,
                      onChanged: onToggleOpen,
                      activeTrackColor: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      store.isApproved
                          ? Icons.verified_rounded
                          : Icons.pending_rounded,
                      size: 16,
                      color: store.isApproved ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      store.isApproved ? 'Approved' : 'Pending',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: store.isApproved,
                      onChanged: onToggleApproved,
                      activeTrackColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
