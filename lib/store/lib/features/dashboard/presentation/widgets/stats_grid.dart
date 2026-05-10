import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';

class DashboardStatsGrid extends StatelessWidget {
  final bool isLoading;
  final double revenue;
  final int totalOrders;
  final int pendingOrders;
  final int preparingOrders;

  const DashboardStatsGrid({
    super.key,
    required this.isLoading,
    required this.revenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.preparingOrders,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (isLoading) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: List.generate(4, (_) => _shimmerCard(surface, border)),
      );
    }

    final stats = [
      _StatItem(
        label: 'Revenue',
        value: '₦${revenue.toStringAsFixed(0)}',
        icon: Icons.payments_rounded,
        color: AppColors.primary,
      ),
      _StatItem(
        label: 'Total Orders',
        value: '$totalOrders',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF6366F1),
      ),
      _StatItem(
        label: 'Pending',
        value: '$pendingOrders',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _StatItem(
        label: 'Preparing',
        value: '$preparingOrders',
        icon: Icons.soup_kitchen_rounded,
        color: const Color(0xFF06B6D4),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: stats
          .map((s) => _statCard(s, surface, border, textColor, muted))
          .toList(),
    );
  }

  Widget _statCard(
    _StatItem item,
    Color surface,
    Color border,
    Color textColor,
    Color muted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(item.label, style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard(Color surface, Color border) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
