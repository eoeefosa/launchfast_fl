import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LaunchFastSplashScreen extends StatefulWidget {
  const LaunchFastSplashScreen({super.key});

  @override
  State<LaunchFastSplashScreen> createState() => _LaunchFastSplashScreenState();
}

class _LaunchFastSplashScreenState extends State<LaunchFastSplashScreen> {
  @override
  Widget build(BuildContext context) {
    // Brand Colors
    const Color brandOrange = Color(0xFFF47C20); // Extracted from your logo
    const Color brandDark = Color(0xFF333333);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle background radial glow for depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [brandOrange.withValues(alpha: 0.05), Colors.white],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // THE LOGO ICON
                Image.asset(
                      'assets/appicon.png', // Just the cloche/rocket part
                      height: 120,
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic)
                    .shimmer(
                      delay: 800.ms,
                      duration: 1500.ms,
                      color: Colors.white.withValues(alpha: 0.5),
                    ), // Premium shader sweep

                const SizedBox(height: 24),

                // THE BRAND NAME
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                          "Launch",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: brandDark,
                            letterSpacing: -1,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    Text(
                          "fast",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: brandOrange,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -1,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),

                const SizedBox(height: 8),

                // SUBTITLE WITH SPACING
                Text(
                      "FOOD DELIVERY",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: brandDark.withValues(alpha: 0.6),
                        letterSpacing: 6,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 1000.ms)
                    .blurXY(begin: 10, end: 0), // Smooth "focus" effect
              ],
            ),
          ),

          // Bottom loading indicator (Discrete & Professional)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: brandOrange.withValues(alpha: 0.1),
                  color: brandOrange,
                ),
              ).animate().fadeIn(delay: 1500.ms),
            ),
          ),
        ],
      ),
    );
  }
}
