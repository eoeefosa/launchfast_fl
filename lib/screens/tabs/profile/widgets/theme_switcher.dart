import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:launchfast/providers/theme_provider.dart';
import 'package:launchfast/screens/tabs/profile/widgets/theme_option.dart';
import 'package:provider/provider.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 4),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDark
                        ? Icons.dark_mode_rounded
                        : themeProvider.isLight
                        ? Icons.light_mode_rounded
                        : Icons.brightness_auto_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        themeProvider.isDark
                            ? 'Dark Mode'
                            : themeProvider.isLight
                            ? 'Light Mode'
                            : 'System Default',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                ThemeOption(
                    label: 'Light',
                    icon: Icons.light_mode_rounded,
                    selected: themeProvider.isLight,
                    onTap: () => themeProvider.setTheme(ThemeMode.light),
                  ),
                ThemeOption(
                    label: 'System',
                    icon: Icons.brightness_auto_rounded,
                    selected: themeProvider.isSystem,
                    onTap: () => themeProvider.setTheme(ThemeMode.system),
                  ),
                ThemeOption(
                    label: 'Dark',
                    icon: Icons.dark_mode_rounded,
                    selected: themeProvider.isDark,
                    onTap: () => themeProvider.setTheme(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}
