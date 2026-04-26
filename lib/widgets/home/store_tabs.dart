import 'package:flutter/material.dart';
import '../../models/store.dart';

class StoreTabs extends StatelessWidget {
  final List<Store> stores;
  final String activeStoreId;
  final ValueChanged<String> onSelect;

  const StoreTabs({
    super.key,
    required this.stores,
    required this.activeStoreId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          final isActive = store.id == activeStoreId;
          final accentColor = store.accentColor;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelect(store.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? accentColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? accentColor
                        : scheme.onSurface.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    store.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? accentColor
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
