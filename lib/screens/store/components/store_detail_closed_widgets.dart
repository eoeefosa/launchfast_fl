import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kBorderRadius = 24.0;

class StoreClosedBanner extends StatelessWidget {
  const StoreClosedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(_kBorderRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: scheme.onInverseSurface,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'This store is currently not taking orders.',
                  style: TextStyle(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoreClosedDialog extends StatelessWidget {
  const StoreClosedDialog({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kBorderRadius),
      ),
      title: Text(
        'Store Closed',
        style: TextStyle(fontWeight: FontWeight.w900, color: scheme.onSurface),
      ),
      content: Text(
        'This store just closed and is no longer accepting orders. '
        'You can still browse the menu, but items cannot be added to your cart.',
        style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('I Understand'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            context.go('/home');
          },
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}
