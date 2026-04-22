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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Row(
        children: stores.map((store) {
          final isActive = store.id == activeStoreId;
          final accentColor = Color(int.parse(store.accentColor.replaceFirst('#', '0xFF')));
          
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(store.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: isActive 
                      ? Border(bottom: BorderSide(color: accentColor, width: 2.5))
                      : null,
                ),
                child: Text(
                  store.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? accentColor : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
