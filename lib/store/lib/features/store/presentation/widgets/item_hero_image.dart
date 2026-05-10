import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';

class ItemHeroImage extends StatelessWidget {
  final String imageUrl;
  final Animation<double>? heroScale;

  const ItemHeroImage({
    super.key,
    required this.imageUrl,
    this.heroScale,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: imageUrl.isNotEmpty
              ? (heroScale != null
                  ? ScaleTransition(
                      scale: heroScale!,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.fastfood,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fastfood,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ))
              : const Center(
                  child: Icon(
                    Icons.fastfood,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        // Back Button & Favorite
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(
                context,
                Icons.arrow_back_ios_new,
                () => Navigator.pop(context),
              ),
              _buildIconButton(
                context,
                Icons.favorite_border,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).cardColor.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
