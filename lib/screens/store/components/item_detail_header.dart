import 'package:flutter/material.dart';
import '../../../models/menu_item.dart';

// ─────────────────────────────────────────────
//  Item header — name, price, store badge
// ─────────────────────────────────────────────

class ItemDetailHeader extends StatelessWidget {
  final MenuItem item;
  final dynamic store;
  final Color accentColor;
  final bool isDark;

  const ItemDetailHeader({
    super.key,
    required this.item,
    required this.store,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.white70 : Colors.grey[600];
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.grey[100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₦${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: -0.5,
                  ),
                ),
                if (item.isPerPortion)
                  Text(
                    '/ portion',
                    style: TextStyle(fontSize: 11, color: labelColor),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          item.description,
          style: TextStyle(fontSize: 15, color: labelColor, height: 1.6),
        ),
        const SizedBox(height: 18),
        ItemDetailStoreBadge(
          storeName: store.name,
          accentColor: accentColor,
          surfaceColor: surfaceColor!,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Store badge
// ─────────────────────────────────────────────

class ItemDetailStoreBadge extends StatelessWidget {
  final String storeName;
  final Color accentColor;
  final Color surfaceColor;

  const ItemDetailStoreBadge({
    super.key,
    required this.storeName,
    required this.accentColor,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'From $storeName',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
