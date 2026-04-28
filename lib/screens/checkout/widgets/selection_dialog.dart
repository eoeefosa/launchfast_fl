import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'selection_option.dart';

class SelectionDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<SelectionOption> options;

  const SelectionDialog({
    super.key,
    required this.title,
    required this.options,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ...options.indexed.map(
                  (e) => e.$2
                      .animate(delay: (e.$1 * 80).ms)
                      .fadeIn()
                      .slideY(begin: 0.1),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 180.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }
}
