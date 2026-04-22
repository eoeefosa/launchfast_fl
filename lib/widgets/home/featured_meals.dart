import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

class FeaturedMeals extends StatelessWidget {
  final List<MenuItem> items;
  final Function(MenuItem) onAdd;

  const FeaturedMeals({
    super.key,
    required this.items,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Featured',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Icon(Icons.arrow_forward, size: 18, color: Colors.grey),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildFeaturedCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(BuildContext context, MenuItem item) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background Image
            Hero(
              tag: 'featured-${item.id}',
              child: CachedNetworkImage(
                imageUrl: item.image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            // Glassmorphism Info Card
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₦${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onAdd(item),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Rating Badge
            Positioned(
              top: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
