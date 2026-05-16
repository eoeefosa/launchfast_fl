import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

const _kAppBarExpandedHeight = 280.0;

class StoreAppBar extends StatelessWidget {
  const StoreAppBar({
    super.key,
    required this.store,
    required this.scheme,
    required this.isDark,
  });

  final dynamic store;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accentColor = store.accentColor as Color;

    return SliverAppBar(
      expandedHeight: _kAppBarExpandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: scheme.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: CircleIconButton(
            icon: Icons.arrow_back_rounded,
            scheme: scheme,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleIconButton(
            icon: Icons.share_rounded,
            scheme: scheme,
            onPressed: () {
              final String name = store.name as String;
              final String tagline = store.tagline as String;
              Share.share(
                'Check out $name on CampusChow! $tagline\n\n'
                'Order your favorite meals now!',
                subject: 'Delicious food from $name',
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: AppBarBackground(
          accentColor: accentColor,
          isOpen: store.isOpen as bool,
          isDark: isDark,
          scheme: scheme,
        ),
      ),
    );
  }
}

class AppBarBackground extends StatelessWidget {
  const AppBarBackground({
    super.key,
    required this.accentColor,
    required this.isOpen,
    required this.isDark,
    required this.scheme,
  });

  final Color accentColor;
  final bool isOpen;
  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accentColor, accentColor.withValues(alpha: 0.6)],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.storefront_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.2),
            ).animate().scale(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x4D000000)],
            ),
          ),
        ),
        if (!isOpen)
          ColoredBox(
            color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.4),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x4D000000), blurRadius: 20),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'CLOSED',
                    style: TextStyle(
                      color: scheme.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.scheme,
    required this.onPressed,
  });

  final IconData icon;
  final ColorScheme scheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: scheme.onSurface, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
