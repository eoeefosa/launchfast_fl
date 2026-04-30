import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/common/universal_image.dart';

// ─────────────────────────────────────────────
//  Hero image with gradient overlay
// ─────────────────────────────────────────────

class ItemDetailHero extends StatelessWidget {
  final String imageUrl;
  final Animation<double> heroScale;

  const ItemDetailHero({
    super.key,
    required this.imageUrl,
    required this.heroScale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ScaleTransition(
            scale: heroScale,
            child: UniversalImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: Container(
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: Container(
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
          // Gradient overlay for legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: ItemDetailCloseButton(onPressed: () => context.pop()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Close button
// ─────────────────────────────────────────────

class ItemDetailCloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ItemDetailCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
