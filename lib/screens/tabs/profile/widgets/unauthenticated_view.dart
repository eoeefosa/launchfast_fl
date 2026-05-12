import 'package:campuschow/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class UnauthenticatedView extends StatelessWidget {
  const UnauthenticatedView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Theme Toggler
            Positioned(
              top: 10,
              right: 16,
              child: IconButton(
                onPressed: () {
                  final newMode = themeProvider.isDark ? ThemeMode.light : ThemeMode.dark;
                  themeProvider.setTheme(newMode);
                },
                icon: Icon(
                  themeProvider.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: scheme.onSurface,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        // Refined colors for a more "premium" look
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primary.withValues(alpha: 0.25),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 80,
                        color: primary,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 32),
                    Text(
                      'Join the Experience',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: scheme.onSurface,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to access your wallet, orders, and personalized settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
