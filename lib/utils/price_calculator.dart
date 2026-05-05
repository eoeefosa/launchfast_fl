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
      item.selectedMeats!.forEach((type, count) {
        price += (meatPrices[type] ?? 0) * count;
      });
    }

    if (item.hasSalad) {
      price += saladPrice;
    }

    if (item.selectedAddons != null) {
      item.selectedAddons!.forEach((addonId, count) {
        final addonItem = allMenuItems.firstWhereOrNull((m) => m.id == addonId);
        if (addonItem != null) {
          price += addonItem.price * count;
        }
      });
    }

    return price * item.quantity;
  }

  static double computeTotal({
    required MenuItem item,
    required int quantity,
    required Map<String, int> selectedMeats,
    required bool hasSalad,
    required Map<String, int> selectedAddons,
    required String? selectedSoupId,
    required List<MenuItem> availableSoups,
    required List<MenuItem> availableAddons,
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
    
    selectedMeats.forEach(
      (type, count) => total += (meatPrices[type] ?? 0) * count,
    );
    
    if (hasSalad) total += saladPrice;
    
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
      item.selectedMeats!.forEach((type, count) {
        if (count > 0) parts.add('$count x $type Meat');
      });
    }

    if (item.hasSalad) {
      parts.add('Salad');
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

    return parts.join(' • ');
  }
}
