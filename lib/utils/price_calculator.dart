import 'package:collection/collection.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';

/// Pure-Dart utility for calculating the total price of a menu item 
/// and its selected options.
///
/// All pricing data (meat prices, salad price, menu items for addon lookup)
/// is passed in as parameters — this class has ZERO dependency on StaticData.
/// The caller (typically a Provider or UI widget) is responsible for supplying
/// the correct, up-to-date values.
abstract final class PriceCalculator {
  /// Calculates the price for a [CartItem] based on its selections.
  static double calculateCartItemPrice(
    CartItem item, {
    required Map<String, double> meatPrices,
    required double saladPrice,
    required List<MenuItem> allMenuItems,
  }) {
    double price = item.menuItem.price;

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
  }) {
    var total = item.price;
    
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

  /// Returns a dot-separated string describing the [CartItem]'s customizations.
  static String getCustomizationSummary(
    CartItem item, {
    required List<MenuItem> allMenuItems,
  }) {
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
