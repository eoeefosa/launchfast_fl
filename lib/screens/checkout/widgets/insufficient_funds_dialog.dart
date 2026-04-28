import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/checkout/top_up_sheet.dart';

class InsufficientFundsDialog extends StatelessWidget {
  final double balance;
  final double total;
  final VoidCallback onPayWithPaystack;

  const InsufficientFundsDialog({
    super.key,
    required this.balance,
    required this.total,
    required this.onPayWithPaystack,
  });

  @override
  Widget build(BuildContext context) {
    final shortfall = total - balance;
    final screenContext = context;

    return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 44,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Insufficient Balance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You need ₦${shortfall.toStringAsFixed(0)} more to complete this order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                _FundsRow(
                  label: 'Your Balance',
                  value: '₦${balance.toStringAsFixed(0)}',
                  color: Colors.red,
                ),
                _FundsRow(
                  label: 'Order Total',
                  value: '₦${total.toStringAsFixed(0)}',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                _FundsRow(
                  label: 'Top-up Needed',
                  value: '₦${shortfall.toStringAsFixed(0)}',
                  color: Colors.orange,
                  bold: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await showModalBottomSheet<bool>(
                        context: screenContext,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => TopUpSheet(initialAmount: shortfall),
                      );
                    },
                    child: const Text(
                      'Top Up Wallet',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onPayWithPaystack,
                  child: const Text('Pay with Paystack instead'),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }
}

class _FundsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _FundsRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
