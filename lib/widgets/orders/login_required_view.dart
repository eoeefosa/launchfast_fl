import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';

class LoginRequiredView extends StatelessWidget {
  const LoginRequiredView({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIOS
                    ? CupertinoIcons.lock_shield
                    : Icons.shopping_bag_outlined,
                size: 70,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 40),
            const Text(
              'Join LaunchFast',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              'Sign in to track your delicious meals in real-time and view your order history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: _SignInButton(isIOS: isIOS),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final bool isIOS;

  const _SignInButton({required this.isIOS});

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => context.push('/login'),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Get Started',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => context.push('/login'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
      ),
      child: const Text(
        'Get Started',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
