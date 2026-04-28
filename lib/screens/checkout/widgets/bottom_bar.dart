import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_spacing.dart';

class BottomBar extends StatelessWidget {
  final double total;
  final bool isLoading;
  final bool isWalletInsufficient;
  final bool hasQueuedItems;
  final VoidCallback onPlaceOrder;
  final VoidCallback? onInsufficientFunds;

  const BottomBar({
    super.key,
    required this.total,
    required this.isLoading,
    required this.isWalletInsufficient,
    required this.hasQueuedItems,
    required this.onPlaceOrder,
    this.onInsufficientFunds,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [AppShadows.softCard],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                        '₦${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate(key: ValueKey(total))
                      .scale(begin: const Offset(0.95, 0.95)),
                ],
              ),
            ),
            GestureDetector(
              onTap: (isLoading || isWalletInsufficient)
                  ? (isWalletInsufficient ? onInsufficientFunds : null)
                  : onPlaceOrder,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: isWalletInsufficient
                      ? null
                      : LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                  color: isWalletInsufficient
                      ? Colors.red.withValues(alpha: 0.12)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isWalletInsufficient) ...[
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Top Up Required',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else
                            Text(
                              hasQueuedItems ? 'Join Queue' : 'Place Order',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
