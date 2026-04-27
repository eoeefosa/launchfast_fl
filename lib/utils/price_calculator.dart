import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../constants/static_data.dart';

/// Pure-Dart utility for calculating the total price of a menu item 
/// and its selected options.
abstract final class PriceCalculator {
  /// Calculates the price for a [CartItem] based on its selections.
  static double calculateCartItemPrice(CartItem item) {
    double price = item.menuItem.price;

    if (item.selectedMeats != null) {
      item.selectedMeats!.forEach((type, count) {
        price += (StaticData.meatPrices[type] ?? 0) * count;
      });
    }

    if (item.hasSalad) {
      price += StaticData.saladPrice;
    }

    if (item.selectedAddons != null) {
      item.selectedAddons!.forEach((addonId, count) {
        // We look up addon prices in the master list. 
        // In a real app, these prices would come from a Repository.
        final addonItem = StaticData.menuItems.firstWhere(
          (m) => m.id == addonId,
          orElse: () => item.menuItem,
        );
        price += addonItem.price * count;
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
  }) {
    var total = item.price;
    
    selectedMeats.forEach(
      (type, count) => total += (StaticData.meatPrices[type] ?? 0) * count,
    );
    
    if (hasSalad) total += StaticData.saladPrice;
    
    if (selectedSoupId != null) {
      final soup = availableSoups.firstWhere((s) => s.id == selectedSoupId);
      if (!soup.isFreeWithSwallow) total += soup.price;
    }
    
    selectedAddons.forEach((id, count) {
      final addon = availableAddons.firstWhere((m) => m.id == id);
      total += addon.price * count;
    });
    
    return total * quantity;
  }

  /// Returns a comma-separated string describing the [CartItem]'s customizations.
  static String getCustomizationSummary(CartItem item) {
    final List<String> parts = [];

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
          final addon = StaticData.menuItems.firstWhere((m) => m.id == id);
          parts.add('$count x ${addon.name}');
        }
      });
    }

    return parts.join(' • ');
  }
}
