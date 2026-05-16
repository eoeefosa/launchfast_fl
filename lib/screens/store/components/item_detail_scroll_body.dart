import 'package:flutter/material.dart';
import '../../../models/menu_item.dart';
import 'item_detail_hero.dart';
import 'item_detail_header.dart';
import 'item_detail_options.dart';

// ─────────────────────────────────────────────
//  Scrollable body
// ─────────────────────────────────────────────

class ItemDetailScrollBody extends StatelessWidget {
  final AnimationController heroController;
  final Animation<double> heroScale;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;

  final MenuItem item;
  final dynamic store;
  final Color accentColor;
  final List<MenuItem> availableSoups;
  final List<MenuItem> availableAddons;
  final List<MenuItem> availableProteins;
  final List<MenuItem> availableSides;
  final List<MenuItem> availableDrinks;

  final Map<String, int> selectedMeats;
  final Map<String, int> selectedAddons;
  final Map<String, int> selectedSides;
  final Map<String, int> selectedDrinks;
  final String? selectedSoupId;
  final bool isDark;

  final void Function(String id, int count) onMeatChanged;
  final void Function(String id, int count) onAddonChanged;
  final void Function(String id, int count) onSideChanged;
  final void Function(String id, int count) onDrinkChanged;
  final void Function(String id) onSoupSelected;

  const ItemDetailScrollBody({
    super.key,
    required this.heroController,
    required this.heroScale,
    required this.contentFade,
    required this.contentSlide,
    required this.item,
    required this.store,
    required this.accentColor,
    required this.availableSoups,
    required this.availableAddons,
    required this.availableProteins,
    required this.availableSides,
    required this.availableDrinks,
    required this.selectedMeats,
    required this.selectedAddons,
    required this.selectedSides,
    required this.selectedDrinks,
    required this.selectedSoupId,
    required this.isDark,
    required this.onMeatChanged,
    required this.onAddonChanged,
    required this.onSideChanged,
    required this.onDrinkChanged,
    required this.onSoupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemDetailHero(imageUrl: item.image, heroScale: heroScale),
          FadeTransition(
            opacity: contentFade,
            child: SlideTransition(
              position: contentSlide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ItemDetailHeader(
                      item: item,
                      store: store,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                    if (availableProteins.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      ItemDetailOptionsSection(
                        title: 'Add Protein',
                        children: availableProteins
                            .map(
                              (meat) => ItemDetailQuantityOption(
                                item: meat,
                                count: selectedMeats[meat.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onMeatChanged(meat.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (availableSides.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      ItemDetailOptionsSection(
                        title: 'Add Sides',
                        children: availableSides
                            .map(
                              (side) => ItemDetailQuantityOption(
                                item: side,
                                count: selectedSides[side.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onSideChanged(side.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (item.type == 'swallow' || item.compatibleWith?.contains('soup') == true) ...[
                      const SizedBox(height: 32),
                      ItemDetailOptionsSection(
                        title: 'Choose a Soup',
                        subtitle: 'Required',
                        children: availableSoups
                            .map(
                              (soup) => ItemDetailSoupOption(
                                soup: soup,
                                isSelected: selectedSoupId == soup.id,
                                accentColor: accentColor,
                                onTap: () => onSoupSelected(soup.id),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (availableDrinks.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      ItemDetailOptionsSection(
                        title: 'Add Drinks',
                        children: availableDrinks
                            .map(
                              (drink) => ItemDetailQuantityOption(
                                item: drink,
                                count: selectedDrinks[drink.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onDrinkChanged(drink.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (availableAddons.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      ItemDetailOptionsSection(
                        title: 'Extras & Add-ons',
                        children: availableAddons
                            .map(
                              (addon) => ItemDetailQuantityOption(
                                item: addon,
                                count: selectedAddons[addon.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onAddonChanged(addon.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
