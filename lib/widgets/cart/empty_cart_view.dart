import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';

class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIOS ? CupertinoIcons.cart : Icons.shopping_cart_outlined,
                  size: 80,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 40),
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
                  fontSize: 16,
                  color: AppColors.lightMuted,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: _BrowseButton(isIOS: isIOS),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
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
    if (isIOS) {
      return CupertinoButton(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        onPressed: () => context.go('/'),
        child: const Text(
          'Start Browsing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => context.go('/'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Start Browsing',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
