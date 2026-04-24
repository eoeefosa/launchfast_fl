import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'label': 'All', 'icon': Icons.restaurant_rounded},
      {'label': 'Rice', 'icon': Icons.rice_bowl_rounded},
      {'label': 'Swallow', 'icon': Icons.cookie_rounded},
      {'label': 'Soup', 'icon': Icons.soup_kitchen_rounded},
      {'label': 'Drinks', 'icon': Icons.local_drink_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: categories.map((cat) {
            final label = cat['label'] as String;
            final icon = cat['icon'] as IconData;
            final isActive = selectedCategory == label;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CategoryChip(
                label: label,
                icon: icon,
                isActive: isActive,
                onTap: () => onCategorySelected(label),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Colors.white
                  : scheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : scheme.onSurface.withValues(alpha: 0.8),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
