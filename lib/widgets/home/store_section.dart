import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/store.dart';
import 'store_tabs.dart';

class StoreSection extends StatelessWidget {
  final List<Store> stores;
  final String activeStoreId;
  final Function(String) onStoreSelected;
  final Color accentColor;

  const StoreSection({
    super.key,
    required this.stores,
    required this.activeStoreId,
    required this.onStoreSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Kitchens',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hand-picked for your taste',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/stores'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Explore All',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        StoreTabs(
          stores: stores,
          activeStoreId: activeStoreId,
          onSelect: onStoreSelected,
        ),
      ],
    );
  }
}
