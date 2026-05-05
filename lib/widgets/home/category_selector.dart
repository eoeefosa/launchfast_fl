import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final List<String> categories;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Standard icon mapping
    IconData getIcon(String label) {
      switch (label.toLowerCase()) {
        case 'all': return Icons.restaurant_rounded;
        case 'rice': return Icons.rice_bowl_rounded;
        case 'swallow': return Icons.cookie_rounded;
        case 'soup': return Icons.soup_kitchen_rounded;
        case 'drinks': return Icons.local_drink_rounded;
        case 'extras': return Icons.add_circle_outline_rounded;
        case 'others': return Icons.more_horiz_rounded;
        default: return Icons.fastfood_rounded;
      }
    }

    final allCategories = ['All', ...categories.where((c) => c != 'All')];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: allCategories.map((label) {
            final isActive = selectedCategory == label;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CategoryChip(
                label: label,
                icon: getIcon(label),
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
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? scheme.onPrimary
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
