import 'package:flutter/material.dart';

class SelectionOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isError;
  final VoidCallback onTap;

  const SelectionOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final activeColor = isError ? Colors.red : primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? activeColor.withValues(alpha: 0.06)
            : isError
            ? Colors.red.withValues(alpha: 0.03)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : isError
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isError && !isSelected ? Icons.warning_amber_rounded : icon,
                    color: isSelected
                        ? Colors.white
                        : isError
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurface,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isSelected
                              ? activeColor
                              : isError
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.75)
                              : isError
                              ? Colors.red.withValues(alpha: 0.75)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: activeColor)
                else if (isError)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.red,
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
