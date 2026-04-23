import 'package:flutter/material.dart';
import 'package:launchfast/constants/static_data.dart';
import 'package:provider/provider.dart';
import 'package:launchfast/constants/app_colors.dart';
import 'package:launchfast/providers/store_provider.dart';
import 'package:launchfast/providers/auth_provider.dart';
import 'package:launchfast/models/menu_item.dart';

class StoreMenuScreen extends StatefulWidget {
  const StoreMenuScreen({super.key});

  @override
  State<StoreMenuScreen> createState() => _StoreMenuScreenState();
}

class _StoreMenuScreenState extends State<StoreMenuScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Rice', 'Swallow', 'Soup', 'Others'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().refreshData();
    });
  }

  List<MenuItem> _getFiltered(List<MenuItem> items) {
    return items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final storeProvider = context.watch<StoreProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;

    // Find store owned by the user
    final ownedStore = storeProvider.stores.firstWhere(
      (s) => s.ownerId == userId,
      orElse: () => storeProvider.stores.isNotEmpty
          ? storeProvider.stores.first
          : StaticData.stores.first,
    );
    final storeId = ownedStore.id;

    final allItems = storeProvider.menuItems
        .where((i) => i.storeId == storeId)
        .toList();
    final filtered = _getFiltered(allItems);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Menu Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => storeProvider.refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () =>
                _showAddEditDialog(context, storeProvider, storeId, null),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Category Filter ──
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    hintStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.search, color: muted),
                    filled: true,
                    fillColor: bg,
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
                const SizedBox(height: 10),
                // Category chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final selected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? AppColors.primary : border,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected ? Colors.white : muted,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Item Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Menu Items ──
          Expanded(
            child: storeProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: muted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          allItems.isEmpty
                              ? 'No menu items yet.\nTap + to add one.'
                              : 'No items match your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _MenuItemCard(
                      item: filtered[i],
                      textColor: textColor,
                      muted: muted,
                      surface: surface,
                      border: border,
                      onEdit: () => _showAddEditDialog(
                        context,
                        storeProvider,
                        storeId,
                        filtered[i],
                      ),
                      onDelete: () =>
                          _confirmDelete(context, storeProvider, filtered[i]),
                      onToggleReady: () =>
                          _toggleItemReady(context, storeProvider, filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddEditDialog(context, storeProvider, storeId, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ─── Toggle item availability ──────────────────────────────────────
  Future<void> _toggleItemReady(
    BuildContext context,
    StoreProvider provider,
    MenuItem item,
  ) async {
    await provider.updateMenuItem(item.id, {'isReady': !item.isReady});
  }

  // ─── Delete Confirmation ───────────────────────────────────────────
  void _confirmDelete(
    BuildContext context,
    StoreProvider provider,
    MenuItem item,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteMenuItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${item.name}" deleted'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Add / Edit Dialog ────────────────────────────────────────────
  void _showAddEditDialog(
    BuildContext context,
    StoreProvider provider,
    String? storeId,
    MenuItem? item,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final priceCtrl = TextEditingController(
      text: item != null ? '${item.price}' : '',
    );
    final imageCtrl = TextEditingController(text: item?.image ?? '');
    String selectedCat = item?.category ?? 'Rice';
    bool isReady = item?.isReady ?? true;
    bool popular = item?.popular ?? false;

    // Auth: get storeId from owned store (best effort)
    // final auth = context.read<AuthProvider>();
    final stores = provider.stores;
    String? storeId;
    if (stores.isNotEmpty) storeId = stores.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) {
            final bg = isDark
                ? AppColors.darkSurface
                : AppColors.lightBackground;
            final textColor = isDark ? AppColors.darkText : AppColors.lightText;
            final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
            final border = isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder;

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 20),
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  Text(
                    isEdit ? 'Edit Menu Item' : 'Add Menu Item',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    'Item Name',
                    nameCtrl,
                    textColor,
                    muted,
                    border,
                    bg,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    'Description',
                    descCtrl,
                    textColor,
                    muted,
                    border,
                    bg,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    'Price (₦)',
                    priceCtrl,
                    textColor,
                    muted,
                    border,
                    bg,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    'Image URL',
                    imageCtrl,
                    textColor,
                    muted,
                    border,
                    bg,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text(
                    'Category',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Rice', 'Swallow', 'Soup', 'Others']
                        .map(
                          (c) => GestureDetector(
                            onTap: () => setModalState(() => selectedCat = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selectedCat == c
                                    ? AppColors.primary
                                    : bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedCat == c
                                      ? AppColors.primary
                                      : border,
                                ),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  color: selectedCat == c
                                      ? Colors.white
                                      : muted,
                                  fontWeight: selectedCat == c
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Toggles
                  _toggleRow(
                    'Available Now',
                    isReady,
                    muted,
                    textColor,
                    border,
                    (v) => setModalState(() => isReady = v),
                  ),
                  const SizedBox(height: 8),
                  _toggleRow(
                    'Mark as Popular',
                    popular,
                    muted,
                    textColor,
                    border,
                    (v) => setModalState(() => popular = v),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final desc = descCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                      if (name.isEmpty || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields'),
                          ),
                        );
                        return;
                      }
                      final data = {
                        'name': name,
                        'description': desc,
                        'price': price,
                        'category': selectedCat,
                        'image': imageCtrl.text.trim().isEmpty
                            ? 'https://placehold.co/400x300?text=$name'
                            : imageCtrl.text.trim(),
                        'isReady': isReady,
                        'popular': popular,
                        if (storeId != null && !isEdit) 'storeId': storeId,
                      };
                      Navigator.pop(ctx);
                      if (isEdit) {
                        await provider.updateMenuItem(item.id, data);
                      } else {
                        await provider.addMenuItem(data);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Item updated successfully'
                                  : 'Item added successfully',
                            ),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? 'Save Changes' : 'Add Item',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    Color textColor,
    Color muted,
    Color border,
    Color fillColor, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: muted),
        filled: true,
        fillColor: fillColor,
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

  Widget _toggleRow(
    String label,
    bool value,
    Color muted,
    Color textColor,
    Color border,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Menu Item Card ───────────────────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final Color textColor;
  final Color muted;
  final Color surface;
  final Color border;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleReady;

  const _MenuItemCard({
    required this.item,
    required this.textColor,
    required this.muted,
    required this.surface,
    required this.border,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 70,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: item.image.isNotEmpty && item.image.startsWith('http')
                    ? Image.network(
                        item.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.fastfood,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.fastfood, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (item.isReady ? Colors.green : Colors.red)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.isReady ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            color: item.isReady
                                ? Colors.green.shade700
                                : Colors.red.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(color: muted, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₦${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (item.popular) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 6),
                IconButton(
                  onPressed: onToggleReady,
                  icon: Icon(
                    item.isReady
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_rounded,
                    color: item.isReady ? Colors.green : Colors.grey,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 6),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
