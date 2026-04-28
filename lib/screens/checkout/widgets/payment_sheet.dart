import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'selection_dialog.dart';
import 'selection_option.dart';

class PaymentSheet extends StatelessWidget {
  final String currentMethod;
  final double balance;
  final double total;
  final bool isInsufficient;
  final ValueChanged<String> onMethodSelected;
  final VoidCallback onInsufficientFunds;

  const PaymentSheet({
    super.key,
    required this.currentMethod,
    required this.balance,
    required this.total,
    required this.isInsufficient,
    required this.onMethodSelected,
    required this.onInsufficientFunds,
  });

  static void show({
    required BuildContext context,
    required String current,
    required double balance,
    required double total,
    required bool isInsufficient,
    required ValueChanged<String> onSelected,
    required VoidCallback onInsufficientFunds,
  }) {
    showDialog(
      context: context,
      builder: (context) => PaymentSheet(
        currentMethod: current,
        balance: balance,
        total: total,
        isInsufficient: isInsufficient,
        onMethodSelected: onSelected,
        onInsufficientFunds: onInsufficientFunds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      title: 'Payment Method',
      subtitle: isInsufficient && currentMethod == 'Wallet'
          ? 'Your wallet balance is insufficient for this order'
          : null,
      options: [
        SelectionOption(
          title: 'Wallet',
          subtitle: 'Balance: ₦${balance.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          isSelected: currentMethod == 'Wallet',
          isError: isInsufficient,
          onTap: () {
            if (isInsufficient) {
              Navigator.pop(context);
              onInsufficientFunds();
            } else {
              HapticFeedback.selectionClick();
              onMethodSelected('Wallet');
              Navigator.pop(context);
            }
          },
        ),
        SelectionOption(
          title: 'Paystack',
          subtitle: 'Pay securely via card or transfer',
          icon: Icons.payment_rounded,
          isSelected: currentMethod == 'Paystack',
          onTap: () {
            HapticFeedback.selectionClick();
            onMethodSelected('Paystack');
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
