import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:campuschow/store/lib/features/store/data/store_model.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';
import 'store_provider.dart';
import 'widgets/store_detail_header.dart';
import 'widgets/menu_item_card.dart';

class StoreDetailScreen extends StatefulWidget {
  final String id;
  const StoreDetailScreen({super.key, required this.id});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  StreamSubscription? _alertSub;

  @override
  void initState() {
    super.initState();
    _setupAlertListener();
  }

  void _setupAlertListener() {
    final provider = context.read<StoreProvider>();
    _alertSub = provider.alertStream.listen((alert) {
      if (alert == 'STORE_CLOSED:${widget.id}') {
        _showClosedDialog();
      }
    });
  }

  void _showClosedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Store Closed', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'This store has just been closed.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Pop dialog
              context.go('/store'); // Go to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final store = storeProvider.stores.where((s) => s.id == widget.id).firstOrNull;
    if (store == null) return const Scaffold(body: Center(child: Text('Store not found')));

    final items = storeProvider.menuItems.where((m) => m.storeId == widget.id).toList();
    final groupedItems = _groupItems(items);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, store),
          SliverToBoxAdapter(child: StoreDetailHeader(store: store, accentColor: store.color)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = groupedItems.keys.elementAt(index);
                return _CategorySection(title: category, items: groupedItems[category]!, storeIsOpen: store.isOpen);
              },
              childCount: groupedItems.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Map<String, List<MenuItem>> _groupItems(List<MenuItem> items) {
    final grouped = <String, List<MenuItem>>{};
    for (var cat in ['Rice', 'Swallow', 'Soup', 'Others']) {
      final catItems = items.where((i) => i.category == cat).toList();
      if (catItems.isNotEmpty) grouped[cat] = catItems;
    }
    return grouped;
  }

  Widget _buildAppBar(BuildContext context, Store store) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: store.color,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: store.color, child: const Center(child: Icon(Icons.storefront_rounded, size: 80, color: Colors.white30))),
            if (!store.isOpen) Container(color: Colors.black54, child: Center(child: _ClosedBadge())),
          ],
        ),
      ),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()),
    );
  }
}

class _ClosedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Text('CLOSED', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<MenuItem> items;
  final bool storeIsOpen;
  const _CategorySection({required this.title, required this.items, required this.storeIsOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ),
          ...items.map((i) => MenuItemCard(
            item: i,
            accent: Theme.of(context).colorScheme.primary,
            onAdd: () => context.push('/item/${i.id}'),
            storeIsOpen: storeIsOpen,
          )),
        ],
      ),
    );
  }
}
