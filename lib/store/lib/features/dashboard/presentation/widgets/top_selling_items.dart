import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';

import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import '../top_selling_screen.dart';

class DashboardTopSellingItems extends StatelessWidget {
  final bool isLoading;
  final List<MapEntry<String, int>> items;
  final List<Order> orders;

  const DashboardTopSellingItems({
    super.key,
    required this.isLoading,
    required this.items,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || items.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final displayItems = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Selling Items',
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (items.length > 3)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StoreTopSellingScreen(items: items, orders: orders),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: displayItems.map((entry) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  entry.key,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  '${entry.value} sold',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
