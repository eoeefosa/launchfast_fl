import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool constrainWidth;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.constrainWidth = true,
    this.maxWidth = 550,
  });

  /// Check if the current device is a tablet/iPad (shortest side >= 600 dp)
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  @override
  Widget build(BuildContext context) {
    if (!constrainWidth || !isTablet(context)) {
      return child;
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium centered presentation on tablets/iPads
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF3F4F6),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRect(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
