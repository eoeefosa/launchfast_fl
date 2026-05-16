import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';

class OptionsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const OptionsSection({
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
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
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
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
        : isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.grey[200]!;
    final bgColor = isDark
        ? (isSelected
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.03))
        : (isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
              : Colors.white);

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
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey[500],
                        ),
                      ),
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

class StepperControl extends StatelessWidget {
  final int count;
  final Color accentColor;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const StepperControl({
    super.key,
    required this.count,
    required this.accentColor,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimColor = isDark ? Colors.white24 : Colors.black12;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          color: count > 0 ? accentColor : dimColor,
          onTap: count > 0 ? onDecrement : null,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            '$count',
            key: ValueKey(count),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          color: accentColor,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  final MenuItem item;
  final int count;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const OptionTile({
    super.key,
    required this.item,
    required this.count,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionCard(
      title: item.name,
      subtitle: '+₦${item.price.toStringAsFixed(2)}',
      isSelected: count > 0,
      trailing: StepperControl(
        count: count,
        accentColor: accentColor,
        onDecrement: () => onChanged(count - 1),
        onIncrement: () => onChanged(count + 1),
      ),
    );
  }
}

class SaladOption extends StatelessWidget {
  final MenuItem salad;
  final bool isSelected;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const SaladOption({
    super.key,
    required this.salad,
    required this.isSelected,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionCard(
      title: salad.name,
      subtitle: '+₦${salad.price.toStringAsFixed(2)}',
      isSelected: isSelected,
      onTap: () => onChanged(!isSelected),
      trailing: _AnimatedCheckbox(
        value: isSelected,
        accentColor: accentColor,
        onChanged: onChanged,
      ),
    );
  }
}

class _AnimatedCheckbox extends StatelessWidget {
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _AnimatedCheckbox({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? accentColor : Colors.grey.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}

class SoupOption extends StatelessWidget {
  final MenuItem soup;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const SoupOption({
    super.key,
    required this.soup,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionCard(
      title: soup.name,
      subtitle: soup.isFreeWithSwallow
          ? 'Free with swallow'
          : '₦${soup.price.toStringAsFixed(2)}',
      isSelected: isSelected,
      onTap: onTap,
      trailing: RadioDot(isSelected: isSelected, accentColor: accentColor),
    );
  }
}

class RadioDot extends StatelessWidget {
  final bool isSelected;
  final Color accentColor;

  const RadioDot({super.key, required this.isSelected, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
