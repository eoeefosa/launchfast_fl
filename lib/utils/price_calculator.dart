import '../models/menu_item.dart';
import '../constants/static_data.dart';

/// Pure-Dart utility for calculating the total price of a menu item 
/// and its selected options.
abstract final class PriceCalculator {
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
}
