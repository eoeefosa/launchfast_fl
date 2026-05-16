import 'package:collection/collection.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';

abstract final class PriceCalculator {
  static double calculateCartItemPrice(
    CartItem item, {
    required Map<String, double> meatPrices,
    required double saladPrice,
    required List<MenuItem> allMenuItems,
  }) {
    double basePrice = item.menuItem.price;
    
    // Use size price if selected
    if (item.selectedSizeId != null) {
      final size = item.menuItem.sizes.firstWhereOrNull((s) => s.id == item.selectedSizeId);
      if (size != null) {
        basePrice = size.price;
      }
    }

    double price = basePrice;

    if (item.selectedMeats != null) {
      item.selectedMeats!.forEach((key, count) {
        // Try finding by ID first
        final meatItem = allMenuItems.firstWhereOrNull((m) => m.id == key);
        if (meatItem != null) {
          price += meatItem.price * count;
        } else {
          price += (meatPrices[key] ?? 0) * count;
        }
      });
    }

    if (item.selectedSides != null) {
      item.selectedSides!.forEach((key, count) {
        final sideItem = allMenuItems.firstWhereOrNull((m) => m.id == key);
        if (sideItem != null) {
          price += sideItem.price * count;
        } else {
          // Fallback if needed, though usually sides are in allMenuItems
          price += saladPrice * count;
        }
      });
    }

    if (item.selectedDrinks != null) {
      item.selectedDrinks!.forEach((key, count) {
        final drinkItem = allMenuItems.firstWhereOrNull((m) => m.id == key);
        if (drinkItem != null) {
          price += drinkItem.price * count;
        }
      });
    }

    if (item.selectedAddons != null) {
      item.selectedAddons!.forEach((addonId, count) {
        final addonItem = allMenuItems.firstWhereOrNull((m) => m.id == addonId);
        if (addonItem != null) {
          price += addonItem.price * count;
        }
      });
    }

    // Add soup price (0 if free, otherwise the stored price)
    if (item.selectedSoup != null) {
      final soupPrice = (item.selectedSoup!['price'] as num?)?.toDouble() ?? 0.0;
      price += soupPrice;
    }

    return price * item.quantity;
  }

  static double computeTotal({
    required MenuItem item,
    required int quantity,
    required Map<String, int> selectedMeats,
    required Map<String, int> selectedSides,
    required Map<String, int> selectedDrinks,
    required Map<String, int> selectedAddons,
    required String? selectedSoupId,
    required List<MenuItem> availableSoups,
    required List<MenuItem> availableAddons,
    required List<MenuItem> availableMeats,
    required List<MenuItem> availableSides,
    required List<MenuItem> availableDrinks,
    required Map<String, double> meatPrices,
    required double saladPrice,
    String? selectedSizeId,
  }) {
    double basePrice = item.price;

    if (selectedSizeId != null) {
      final size = item.sizes.firstWhereOrNull((s) => s.id == selectedSizeId);
      if (size != null) {
        basePrice = size.price;
      }
    } else if (item.sizes.isNotEmpty) {
      // Default to first size if none selected but sizes exist
      basePrice = item.sizes.first.price;
    }

    var total = basePrice;
    
    selectedMeats.forEach((key, count) {
      final meatItem = availableMeats.firstWhereOrNull((m) => m.id == key);
      if (meatItem != null) {
        total += meatItem.price * count;
      } else {
        total += (meatPrices[key] ?? 0) * count;
      }
    });
    
    selectedSides.forEach((key, count) {
      final sideItem = availableSides.firstWhereOrNull((m) => m.id == key);
      if (sideItem != null) {
        total += sideItem.price * count;
      } else {
        total += saladPrice * count;
      }
    });

    selectedDrinks.forEach((key, count) {
      final drinkItem = availableDrinks.firstWhereOrNull((m) => m.id == key);
      if (drinkItem != null) {
        total += drinkItem.price * count;
      }
    });
    
    if (selectedSoupId != null) {
      final soup = availableSoups.firstWhereOrNull((s) => s.id == selectedSoupId);
      if (soup != null && !soup.isFreeWithSwallow) {
        total += soup.price;
      }
    }
    
    selectedAddons.forEach((id, count) {
      final addon = availableAddons.firstWhereOrNull((m) => m.id == id);
      if (addon != null) {
        total += addon.price * count;
      }
    });
    
    return total * quantity;
  }

  static String getCustomizationSummary(
    CartItem item, {
    required List<MenuItem> allMenuItems,
  }) {
    final List<String> parts = [];

    if (item.selectedSizeId != null) {
      final size = item.menuItem.sizes.firstWhereOrNull((s) => s.id == item.selectedSizeId);
      if (size != null) {
        parts.add(size.name);
      }
    }

    if (item.selectedMeats != null) {
      item.selectedMeats!.forEach((key, count) {
        if (count > 0) {
          final meatItem = allMenuItems.firstWhereOrNull((m) => m.id == key);
          final label = meatItem != null ? meatItem.name : '$key Meat';
          parts.add('$count x $label');
        }
      });
    }

    if (item.selectedSides != null) {
      item.selectedSides!.forEach((key, count) {
        if (count > 0) {
          final sideItem = allMenuItems.firstWhereOrNull((m) => m.id == key);
          final label = sideItem != null ? sideItem.name : 'Side';
          parts.add('$count x $label');
        }
      });
    }

    if (item.selectedDrinks != null) {
      item.selectedDrinks!.forEach((key, count) {
        if (count > 0) {
          final drinkItem = allMenuItems.firstWhereOrNull((m) => m.id == key);
          final label = drinkItem != null ? drinkItem.name : 'Drink';
          parts.add('$count x $label');
        }
      });
    }

    if (item.selectedAddons != null) {
      item.selectedAddons!.forEach((id, count) {
        if (count > 0) {
          final addon = allMenuItems.firstWhere(
            (m) => m.id == id,
            orElse: () => item.menuItem,
          );
          parts.add('$count x ${addon.name}');
        }
      });
    }

    if (item.selectedSoup != null) {
      final soupName = item.selectedSoup!['name'] as String? ?? 'Soup';
      final soupPrice = (item.selectedSoup!['price'] as num?)?.toDouble() ?? 0.0;
      parts.add(soupPrice == 0 ? '$soupName (Free)' : soupName);
    }

    return parts.join(' • ');
  }
}
