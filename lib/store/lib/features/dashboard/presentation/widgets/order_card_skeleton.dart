import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/core/widgets/shimmer_placeholder.dart';

/// Skeleton list shown during initial order load.
/// Pass [count] to control how many cards appear.
class OrderListSkeleton extends StatelessWidget {
  final int count;
  final bool isDark;
  const OrderListSkeleton({super.key, this.count = 5, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: count,
      itemBuilder: (_, i) => _OrderCardSkeleton(isDark: isDark, delay: i * 70),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  final bool isDark;
  final int delay;
  const _OrderCardSkeleton({required this.isDark, required this.delay});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: order ID + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerPlaceholder(width: 100, height: 14, borderRadius: 6),
              ShimmerPlaceholder(width: 72, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          // Customer name
          ShimmerPlaceholder(width: 160, height: 13, borderRadius: 6),
          const SizedBox(height: 8),
          // Items line
          ShimmerPlaceholder(width: double.infinity, height: 12, borderRadius: 6),
          const SizedBox(height: 6),
          ShimmerPlaceholder(width: 200, height: 12, borderRadius: 6),
          const SizedBox(height: 12),
          // Footer: time + amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerPlaceholder(width: 90, height: 12, borderRadius: 6),
              ShimmerPlaceholder(width: 70, height: 16, borderRadius: 6),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 250.ms);
  }
}

/// Single full-page skeleton for the order detail screen.
class OrderDetailSkeleton extends StatelessWidget {
  final bool isDark;
  const OrderDetailSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(surface, border, [
          _row(120, 24),
          const SizedBox(height: 12),
          _row(180, 14),
          const SizedBox(height: 8),
          _row(double.infinity, 13),
          const SizedBox(height: 6),
          _row(double.infinity, 13),
          const SizedBox(height: 6),
          _row(140, 13),
        ]),
        const SizedBox(height: 12),
        _card(surface, border, [
          _row(100, 16),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            Row(children: [
              ShimmerPlaceholder(width: 40, height: 40, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row(double.infinity, 13),
                const SizedBox(height: 6),
                _row(80, 12),
              ])),
              ShimmerPlaceholder(width: 60, height: 14, borderRadius: 6),
            ]),
            const SizedBox(height: 10),
          ],
        ]),
        const SizedBox(height: 12),
        _card(surface, border, [
          _row(80, 16),
          const SizedBox(height: 12),
          _row(double.infinity, 13),
          const SizedBox(height: 8),
          _row(double.infinity, 13),
        ]),
        const SizedBox(height: 12),
        // Action buttons skeleton
        Row(children: [
          Expanded(child: ShimmerPlaceholder(width: double.infinity, height: 44, borderRadius: 12)),
          const SizedBox(width: 12),
          Expanded(child: ShimmerPlaceholder(width: double.infinity, height: 44, borderRadius: 12)),
        ]),
      ],
    );
  }

  Widget _card(Color surface, Color border, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  ShimmerPlaceholder _row(double w, double h) =>
      ShimmerPlaceholder(width: w, height: h, borderRadius: 6);
}
