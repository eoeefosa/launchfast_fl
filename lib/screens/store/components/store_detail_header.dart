import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class StoreHeader extends StatelessWidget {
  const StoreHeader({super.key, required this.store, required this.scheme});

  final dynamic store;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final accentColor = store.accentColor as Color;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.name as String,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                FavouriteButton(
                  accentColor: accentColor,
                  storeId: store.id as String,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              store.tagline as String,
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                StatBadge(
                  icon: Icons.star_rounded,
                  label: store.rating.toString(),
                  iconColor: Colors.amber,
                  scheme: scheme,
                ),
                const SizedBox(width: 12),
                StatBadge(
                  icon: Icons.access_time_filled_rounded,
                  label: store.deliveryTime as String,
                  iconColor: Colors.blue,
                  scheme: scheme,
                ),
                const SizedBox(width: 12),
                StatBadge(
                  icon: Icons.delivery_dining_rounded,
                  label: 'Free',
                  iconColor: Colors.green,
                  scheme: scheme,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.accentColor,
    required this.storeId,
  });

  final Color accentColor;
  final String storeId;

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<AuthProvider, bool>(
      (auth) => auth.user?.favoriteStores.contains(storeId) ?? false,
    );
    final isAuthenticated = context.select<AuthProvider, bool>(
      (auth) => auth.isAuthenticated,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          color: accentColor,
          size: 24,
        ),
        onPressed: !isAuthenticated
            ? null
            : () async {
                try {
                  await context.read<AuthProvider>().toggleFavorite(storeId);
                  if (context.mounted) {
                    HapticFeedback.mediumImpact();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update favorite: $e')),
                    );
                  }
                }
              },
      ),
    );
  }
}

class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
