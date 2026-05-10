import 'package:flutter/material.dart';

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
    final btnBg = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove, color: btnBg, iconColor: count > 0 ? accentColor : Colors.grey, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            width: 16,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        _StepButton(icon: Icons.add, color: accentColor, iconColor: Colors.white, onTap: onIncrement),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
