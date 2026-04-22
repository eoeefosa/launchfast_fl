import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../models/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final Color accent;
  final VoidCallback onAdd;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.accent,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/item/${item.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[100]!, width: 1.5),
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
                        if (item.popular)
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
    );
  }
}
