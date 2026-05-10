import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final Color accent;
  final VoidCallback onAdd;
  final bool storeIsOpen;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.accent,
    required this.onAdd,
    this.storeIsOpen = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = item.isReady && storeIsOpen;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isAvailable ? onAdd : null,
        borderRadius: BorderRadius.circular(24),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isAvailable
                    ? Colors.grey[100]!
                    : Colors.red.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: item.image,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[50]),
                      ),
                    ),
                    if (!item.isReady)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!item.isReady)
                            const Text(
                              'SOLD OUT',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          else if (item.popular)
                            Icon(Icons.stars_rounded, color: accent, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₦${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (item.isPerPortion)
                                Text(
                                  ' / portion',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          if (isAvailable)
                            GestureDetector(
                              onTap: onAdd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
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
