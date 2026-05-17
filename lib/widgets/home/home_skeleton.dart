import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shown while the initial store data loads. Uses flutter_animate's shimmer
/// effect over static placeholder shapes.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final shimmerColor = isDark ? Colors.white10 : Colors.white54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          // NeverScrollableScrollPhysics: skeleton is decorative only.
          physics: const NeverScrollableScrollPhysics(),
          child: _SkeletonContent(baseColor: baseColor)
              // Shimmer runs on a repeating loop.
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms, color: shimmerColor)
              // Fade the whole skeleton in.
              .animate()
              .fade(duration: 300.ms),
        ),
      ),
    );
  }
}

/// The static layout of the skeleton, separated from animation concerns.
class _SkeletonContent extends StatelessWidget {
  const _SkeletonContent({required this.baseColor});

  final Color baseColor;

  /// Convenience builder for a rounded rectangle placeholder.
  Widget _box({
    required double width,
    required double height,
    double radius = 4,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _box(width: 50, height: 50, radius: 25),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(
                    width: 100,
                    height: 14,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  _box(width: 150, height: 20),
                ],
              ),
              const Spacer(),
              _box(width: 40, height: 40, radius: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // "Restaurants" title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _box(width: 120, height: 24),
        ),
        const SizedBox(height: 16),

        // Store cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              3,
              (_) => _box(
                width: 240,
                height: 140,
                radius: 24,
                margin: const EdgeInsets.only(right: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Category chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              5,
              (_) => _box(
                width: 80,
                height: 40,
                radius: 20,
                margin: const EdgeInsets.only(right: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Menu item cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(
                width: 100,
                height: 20,
                margin: const EdgeInsets.only(bottom: 16),
              ),
              ...List.generate(
                3,
                (_) => _box(
                  width: double.infinity,
                  height: 110,
                  radius: 20,
                  margin: const EdgeInsets.only(bottom: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
