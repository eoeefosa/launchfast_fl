import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';

class DashboardTopSellingItems extends StatelessWidget {
  final bool isLoading;
  final List<MapEntry<String, int>> items;

  const DashboardTopSellingItems({
    super.key,
    required this.isLoading,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || items.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Selling Items',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
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
            children: items.map((entry) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  entry.key,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '${entry.value} sold',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
