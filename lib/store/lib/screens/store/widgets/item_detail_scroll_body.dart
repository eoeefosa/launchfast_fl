import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';
import 'item_detail_hero.dart';
import 'item_detail_header.dart';
import 'item_detail_options.dart';

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
  final List<MenuItem> availableMeats;
  final List<MenuItem> availableSalads;

  final Map<String, int> selectedMeats;
  final Map<String, int> selectedSides;
  final Map<String, int> selectedDrinks;
  final Map<String, int> selectedAddons;
  final String? selectedSoupId;
  final bool isDark;

  final void Function(String id, int count) onMeatChanged;
  final void Function(String id, int count) onSideChanged;
  final void Function(String id, int count) onDrinkChanged;
  final void Function(String id, int count) onAddonChanged;
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
    required this.availableMeats,
    required this.availableSalads,
    required this.selectedMeats,
    required this.selectedSides,
    required this.selectedDrinks,
    required this.selectedAddons,
    required this.selectedSoupId,
    required this.isDark,
    required this.onMeatChanged,
    required this.onSideChanged,
    required this.onDrinkChanged,
    required this.onAddonChanged,
    required this.onSoupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemHeroImage(imageUrl: item.image, heroScale: heroScale),
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
                    if (availableMeats.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      OptionsSection(
                        title: 'Add Meat',
                        children: availableMeats
                            .map(
                              (meat) => OptionTile(
                                item: meat,
                                count: selectedMeats[meat.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onMeatChanged(meat.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (availableAddons.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      OptionsSection(
                        title: 'Add-ons',
                        children: availableAddons
                            .map(
                              (addon) => OptionTile(
                                item: addon,
                                count: selectedAddons[addon.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onAddonChanged(addon.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (availableSalads.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      OptionsSection(
                        title: 'Add Sides',
                        children: availableSalads
                            .map(
                              (side) => OptionTile(
                                item: side,
                                count: selectedSides[side.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onSideChanged(side.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (item.category == 'Swallow') ...[
                      const SizedBox(height: 32),
                      OptionsSection(
                        title: 'Choose a Soup',
                        subtitle: 'Required',
                        children: availableSoups
                            .map(
                              (soup) => SoupOption(
                                soup: soup,
                                isSelected: selectedSoupId == soup.id,
                                accentColor: accentColor,
                                onTap: () => onSoupSelected(soup.id),
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
