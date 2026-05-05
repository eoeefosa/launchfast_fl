import 'dart:io';
import 'package:campuschow/providers/store_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: SizedBox(
            width: double.infinity,
            child: _BrowseButton(isIOS: isIOS),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIOS ? CupertinoIcons.cart : Icons.shopping_cart_outlined,
                  size: 60,
                  color: scheme.primary.withValues(alpha: 0.25),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              const Text(
                'Your cart is empty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                "Looks like you haven't added any delicious meals to your cart yet.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Top Rated Stores',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<StoreProvider>(
                builder: (context, storeProvider, _) {
                  final stores = storeProvider.stores;
                  if (stores.isEmpty) return const SizedBox.shrink();

                  return SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: stores.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        return GestureDetector(
                          onTap: () => context.push('/store/${store.id}'),
                          child: Container(
                            width: 220,
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: scheme.onSurface.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          store.accentColor,
                                          store.accentColor.withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        size: 48,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        store.tagline,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurface.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseButton extends StatelessWidget {
  final bool isIOS;
  const _BrowseButton({required this.isIOS});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isIOS) {
      return CupertinoButton(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20),
        onPressed: () => context.go('/home'),
        child: const Text(
          'Start Browsing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // explicit — not inherited from theme
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => context.go('/home'),
      style:
          ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            // Force white text even if theme overrides foregroundColor
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ).copyWith(
            // Belt-and-suspenders: override MaterialStateProperty directly
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
      child: const Text(
        'Start Browsing',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white, // hardcoded — bypasses all theme inheritance
        ),
      ),
    );
  }
}
