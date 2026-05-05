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

  final Map<String, int> selectedMeats;
  final Map<String, int> selectedAddons;
  final bool hasSalad;
  final String? selectedSoupId;
  final Map<String, double> meatPrices;
  final double saladPrice;
  final bool isDark;

  final void Function(String type, int count) onMeatChanged;
  final void Function(String id, int count) onAddonChanged;
  final void Function(bool val) onSaladChanged;
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
    required this.selectedMeats,
    required this.selectedAddons,
    required this.hasSalad,
    required this.selectedSoupId,
    required this.meatPrices,
    required this.saladPrice,
    required this.isDark,
    required this.onMeatChanged,
    required this.onAddonChanged,
    required this.onSaladChanged,
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
                    const SizedBox(height: 32),
                    ItemDetailOptionsSection(
                      title: 'Add Meat',
                      children: [
                        ItemDetailMeatOption(
                          type: 'Small',
                          price: meatPrices['Small']!,
                          count: selectedMeats['Small']!,
                          accentColor: accentColor,
                          onChanged: (c) => onMeatChanged('Small', c),
                        ),
                        ItemDetailMeatOption(
                          type: 'Big',
                          price: meatPrices['Big']!,
                          count: selectedMeats['Big']!,
                          accentColor: accentColor,
                          onChanged: (c) => onMeatChanged('Big', c),
                        ),
                      ],
                    ),
                    if (availableAddons.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      ItemDetailOptionsSection(
                        title: 'Add-ons',
                        children: availableAddons
                            .map(
                              (addon) => ItemDetailAddonOption(
                                addon: addon,
                                count: selectedAddons[addon.id] ?? 0,
                                accentColor: accentColor,
                                onChanged: (c) => onAddonChanged(addon.id, c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (item.category == 'Rice' || item.name == 'Moi Moi') ...[
                      const SizedBox(height: 32),
                      ItemDetailOptionsSection(
                        title: 'Extras',
                        children: [
                          ItemDetailSaladOption(
                            hasSalad: hasSalad,
                            price: saladPrice,
                            accentColor: accentColor,
                            onChanged: onSaladChanged,
                          ),
                        ],
                      ),
                    ],
                    if (item.category == 'Swallow') ...[
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
