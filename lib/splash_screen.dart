import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/common/loading_indicator.dart';

/// CampusChow launch / loading screen.
///
/// Responsibility: animate the brand while auth initialises.
///
/// Navigation responsibility: NONE — the router's `redirect` clause watches
/// [AuthProvider] via `refreshListenable`. The moment `auth.isLoading` flips
/// to `false`, the router fires and sends the user to the correct screen
/// for their role. The splash never calls `context.go(...)`.
class CampusChowSplashScreen extends StatelessWidget {
  const CampusChowSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Guaranteed background color
          Container(color: scheme.surface),
          
          // Subtle radial glow for depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    scheme.primary.withValues(alpha: 0.1),
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Campus Chow Logo',
                  image: true,
                  child: Image.asset(
                    'assets/appicon.png', 
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.fastfood_rounded,
                      size: 120,
                      color: scheme.primary,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic)
                      .shimmer(
                        delay: 800.ms,
                        duration: 1500.ms,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                ),

                const SizedBox(height: 24),

                // Brand name
                Semantics(
                  label: 'Campus Chow',
                  header: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                            'Campus',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: -1,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideY(begin: 0.2, end: 0),
                      Text(
                            'Chow',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -1,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                      'FOOD DELIVERY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 6,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 1000.ms)
                    .blurXY(begin: 10, end: 0),
              ],
            ),
          ),

          // Bottom loading bar — visible while auth is being read from storage
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: const CampusChowLoading(size: 32)
                .animate()
                .fadeIn(delay: 1000.ms, duration: 800.ms),
          ),
        ],
      ),
    );
  }
}
