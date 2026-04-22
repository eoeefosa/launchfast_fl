import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/store_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/menu_item.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final authProvider = context.watch<AuthProvider>();
    final store = authProvider.adminStore;

    if (store == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final storeItems = storeProvider.menuItems
        .where((i) => i.storeId == store.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Menu')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: storeItems.length,
        itemBuilder: (context, index) {
          final item = storeItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${item.category}${item.isPerPortion ? " (Per Portion)" : ""}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      Text(
                        '₦${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _showEditDialog(context, storeProvider, item),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                ),
                IconButton(
                  onPressed: () => storeProvider.deleteMenuItem(item.id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showEditDialog(context, storeProvider, null, storeId: store.id),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    StoreProvider storeProvider,
    MenuItem? item, {
    String? storeId,
  }) {
    final nameController = TextEditingController(text: item?.name);
    final priceController = TextEditingController(text: item?.price.toString());
    String category = item?.category ?? 'Rice';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item == null ? 'Add New Item' : 'Edit Item',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price (₦)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: category,
              items: [
                'Rice',
                'Swallow',
                'Soup',
                'Others',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => category = val!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final data = {
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'category': category,
                  'storeId': storeId ?? item!.storeId,
                  'image':
                      item?.image ??
                      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=300',
                  'description': 'Delicious food',
                };
                if (item == null) {
                  storeProvider.addMenuItem(data);
                } else {
                  storeProvider.updateMenuItem(item.id, data);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text(
                'Save Item',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
