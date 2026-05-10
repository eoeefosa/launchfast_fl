import 'package:flutter/material.dart';

class OptionSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const OptionSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              _SubtitleBadge(text: subtitle!, isDark: isDark),
            ],
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

class _SubtitleBadge extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SubtitleBadge({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange, letterSpacing: 0.3),
      ),
    );
  }
}

class SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  const SelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    final borderColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.6)
        : isDark ? Colors.white.withValues(alpha: 0.09) : Colors.grey[200]!;
        
    final bgColor = isDark
        ? (isSelected ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03))
        : (isSelected ? theme.colorScheme.primary.withValues(alpha: 0.04) : Colors.white);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey[500])),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
