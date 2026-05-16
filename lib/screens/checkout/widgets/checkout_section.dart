import 'package:flutter/material.dart';

class CheckoutSection extends StatelessWidget {
  const CheckoutSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
