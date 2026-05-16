import '../../../models/menu_item.dart';

class AvailableComponents {
  final List<MenuItem> soups;
  final List<MenuItem> proteins;
  final List<MenuItem> sides;
  final List<MenuItem> drinks;
  final List<MenuItem> addons;

  AvailableComponents({
    required this.soups,
    required this.proteins,
    required this.sides,
    required this.drinks,
    required this.addons,
  });
}
