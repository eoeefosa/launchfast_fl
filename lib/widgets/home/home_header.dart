import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'package:go_router/go_router.dart';
import 'location_selector.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (user?.name != null && user!.name.isNotEmpty)
                          ? '${user.name} 👋'
                          : 'Guest User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderActions(user: user, primaryColor: primaryColor),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: LocationSelector()),
              const SizedBox(width: 12),
              Semantics(
                label: 'Search for food',
                button: true,
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Tooltip(
                    message: 'Search',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

class _HeaderActions extends StatelessWidget {
  final dynamic user;
  final Color primaryColor;

  const _HeaderActions({required this.user, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Semantics(
          label: 'Notifications',
          button: true,
          child: GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Tooltip(
              message: 'Notifications',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 26,
                      color: scheme.onSurface,
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, child) {
                      if (provider.unreadCount == 0)
                        return const SizedBox.shrink();
                      return Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${provider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          label: 'View Profile',
          button: true,
          child: GestureDetector(
            onTap: () => context.go('/profile'),
            child: Tooltip(
              message: 'Profile',
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Use a solid, visible border in both modes
                    border: Border.all(
                      color: primaryColor.withValues(alpha: isDark ? 0.6 : 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    // Solid background that's visible in both light and dark
                    backgroundColor: isDark
                        ? primaryColor.withValues(alpha: 0.25)
                        : primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      (user?.name != null && user!.name.trim().isNotEmpty)
                          ? user!.name.trim()[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        // Always use primaryColor for the letter — visible on both backgrounds
                        color: isDark ? Colors.white : primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
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
