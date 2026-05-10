import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';

class AddEditMenuItemDialog extends StatefulWidget {
  final StoreProvider provider;
  final String? storeId;
  final MenuItem? item;

  const AddEditMenuItemDialog({
    super.key,
    required this.provider,
    required this.storeId,
    this.item,
  });

  @override
  State<AddEditMenuItemDialog> createState() => _AddEditMenuItemDialogState();
}

class _AddEditMenuItemDialogState extends State<AddEditMenuItemDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  String? _selectedImageStr; // Can be a URL (from edit) or a base64 string
  late String _selectedCat;
  late bool _isReady;
  late bool _popular;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _priceCtrl = TextEditingController(text: item != null ? '${item.price}' : '');
    _selectedImageStr = item?.image;
    _selectedCat = item?.category ?? 'Rice';
    _isReady = item?.isReady ?? true;
    _popular = item?.popular ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();

    super.dispose();
  }

  void _saveItem() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    
    if (name.isEmpty || price <= 0 || _selectedImageStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a name, price, and image')),
      );
      return;
    }

    final isEdit = widget.item != null;
    final data = {
      'name': name,
      'description': desc,
      'price': price,
      'category': _selectedCat,
      'image': _selectedImageStr,
      'isReady': _isReady,
      'popular': _popular,
      if (widget.storeId != null && !isEdit) 'storeId': widget.storeId,
    };

    Navigator.pop(context);
    
    if (isEdit) {
      await widget.provider.updateMenuItem(widget.item!.id, data);
    } else {
      await widget.provider.addMenuItem(data);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Item updated successfully' : 'Item added successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageStr = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkSurface : AppColors.lightBackground;
        final textColor = isDark ? AppColors.darkText : AppColors.lightText;
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('Take a Photo', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('Choose from Gallery', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isEdit = widget.item != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
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
              _buildField('Item Name', _nameCtrl, textColor, muted, border, bg),
              const SizedBox(height: 14),
              _buildField('Description', _descCtrl, textColor, muted, border, bg, maxLines: 2),
              const SizedBox(height: 14),
              _buildField('Price (₦)', _priceCtrl, textColor, muted, border, bg, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              // ── Image Picker ──
              GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _selectedImageStr != null
                      ? _selectedImageStr!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(_selectedImageStr!.split(',').last),
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              _selectedImageStr!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.error_outline, color: Colors.red),
                              ),
                            )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.primary),
                            const SizedBox(height: 10),
                            Text('Tap to add photo', style: TextStyle(color: muted, fontSize: 14)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Category', style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Rice', 'Swallow', 'Soup', 'Others'].map((c) => GestureDetector(
                  onTap: () => setState(() => _selectedCat = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedCat == c ? AppColors.primary : bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedCat == c ? AppColors.primary : border,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: _selectedCat == c ? Colors.white : muted,
                        fontWeight: _selectedCat == c ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              _toggleRow('Available Now', _isReady, muted, textColor, border, (v) => setState(() => _isReady = v)),
              const SizedBox(height: 8),
              _toggleRow('Mark as Popular', _popular, muted, textColor, border, (v) => setState(() => _popular = v)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Add Item',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
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

void showAddEditMenuItemDialog(
  BuildContext context,
  StoreProvider provider,
  String? storeId,
  MenuItem? item,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddEditMenuItemDialog(
      provider: provider,
      storeId: storeId,
      item: item,
    ),
  );
}
