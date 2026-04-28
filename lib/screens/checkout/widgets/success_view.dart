import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SuccessView extends StatelessWidget {
  const SuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your food is being prepared 🍽️',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            FilledButton.tonal(
              onPressed: () => context.go('/order'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('Back to Home'),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
      ),
    );
  }
}
