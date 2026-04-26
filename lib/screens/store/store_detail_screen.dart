import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';

class StoreDetailScreen extends StatelessWidget {
  final String id;

  const StoreDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final cartProvider = context.read<CartProvider>();

    final store = storeProvider.stores.firstWhere((s) => s.id == id);
    final items = storeProvider.menuItems
        .where((m) => m.storeId == id)
        .toList();

    // Group items by category
    final categories = ['Rice', 'Swallow', 'Soup', 'Others'];
    final groupedItems = <String, List<MenuItem>>{};
    for (var cat in categories) {
      final catItems = items.where((i) => i.category == cat).toList();
      if (catItems.isNotEmpty) groupedItems[cat] = catItems;
    }

    final accentColor = store.accentColor;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: accentColor,
                        child: Center(
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      if (!store.isOpen)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'CLOSED',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                store.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite_outline_rounded,
                                color: accentColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.tagline,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildStatBadge(
                              Icons.star_rounded,
                              store.rating.toString(),
                              Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            _buildStatBadge(
                              Icons.access_time_filled_rounded,
                              store.deliveryTime,
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _buildStatBadge(
                              Icons.delivery_dining_rounded,
                              'Free',
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = groupedItems.keys.elementAt(index);
                  final catItems = groupedItems[category]!;
                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 20),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        ...catItems.map(
                          (item) => _buildMenuItemCard(
                            context,
                            cartProvider,
                            item,
                            accentColor,
                            store.isOpen,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }, childCount: groupedItems.length),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(color: Colors.white, height: 100),
              ),
            ],
          ),
          if (!store.isOpen)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'This store is currently not taking orders.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(
    BuildContext context,
    CartProvider cartProvider,
    MenuItem item,
    Color accent,
    bool storeIsOpen,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: storeIsOpen ? () => context.push('/item/${item.id}') : null,
        borderRadius: BorderRadius.circular(24),
        child: Opacity(
          opacity: storeIsOpen ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[100]!, width: 1.5),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: item.image,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₦${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          if (storeIsOpen)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
