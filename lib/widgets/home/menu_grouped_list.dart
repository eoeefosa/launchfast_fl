import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import 'menu_item_card.dart';

class MenuGroupedList extends StatelessWidget {
  final Map<String, List<MenuItem>> groupedItems;
  final Color accentColor;
  final Function(MenuItem) onAdd;
  final String? emptyMessage;

  const MenuGroupedList({
    super.key,
    required this.groupedItems,
    required this.accentColor,
    required this.onAdd,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedItems.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                emptyMessage ?? "No items found",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = groupedItems.keys.elementAt(index);
          final items = groupedItems[category]!;
          
          return _CategoryGroup(
            category: category,
            items: items,
            accentColor: accentColor,
            onAdd: onAdd,
            index: index,
          );
        },
        childCount: groupedItems.length,
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<MenuItem> items;
  final Color accentColor;
  final Function(MenuItem) onAdd;
  final int index;

  const _CategoryGroup({
    required this.category,
    required this.items,
    required this.accentColor,
    required this.onAdd,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Divider(color: Colors.grey[100], thickness: 1.5),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => MenuItemCard(
              item: item,
              accent: accentColor,
              onAdd: () => onAdd(item),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
