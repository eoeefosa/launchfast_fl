import 'package:flutter/material.dart';
import 'package:campuschow/providers/auth_provider.dart';
import 'package:campuschow/repositories/wallet_repository.dart';
import 'package:campuschow/services/api_service.dart';
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'package:campuschow/utils/ui_utils.dart';
import 'package:campuschow/widgets/pin_entry_sheet.dart';
import 'package:campuschow/widgets/set_pin_sheet.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/screens/auth/widgets/apptextfield.dart';
import 'package:campuschow/screens/auth/widgets/custom_button.dart';

class BuyGiftCardSheet extends StatefulWidget {
  const BuyGiftCardSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BuyGiftCardSheet(),
    );
  }

  @override
  State<BuyGiftCardSheet> createState() => _BuyGiftCardSheetState();
}

class _BuyGiftCardSheetState extends State<BuyGiftCardSheet> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _onPurchasePressed() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final auth = context.read<AuthProvider>();
    if ((auth.user?.walletBalance ?? 0) < amount) {
      UIUtils.showErrorDialog(context, 'Insufficient Balance', 'You do not have enough funds in your wallet.');
      return;
    }

    if (!(auth.user?.hasTransactionPin ?? false)) {
      final pinSet = await SetPinSheet.show(context);
      if (!mounted || !pinSet) return;
    }

    final confirmed = await PinEntrySheet.show(
      context,
      title: 'Enter Transaction PIN',
      onSubmit: (pin) => WalletRepository().verifyTransactionPin(pin),
    );
    if (!mounted || !confirmed) return;

    _buyGiftCard(auth, amount);
  }

  Future<void> _buyGiftCard(AuthProvider auth, double amount) async {
    setState(() => _isLoading = true);
    try {
      final newBalance = await WalletRepository().buyGiftCard(amount);
      if (!mounted) return;

      if (newBalance != null) {
        auth.updateWalletBalance(newBalance);
      } else {
        auth.refreshUser();
      }

      notificationService.showNotification(
        title: 'Gift Card Purchased',
        body: 'Your ₦${amount.toStringAsFixed(2)} gift card code has been sent to your email.',
        payload: 'gift_card_buy',
      );

      Navigator.pop(context);
      UIUtils.showSuccessDialog(
        context,
        'Success',
        'Gift card purchased successfully! The code has been sent to your email.',
      );
    } catch (e) {
      if (mounted) UIUtils.showErrorDialog(context, 'Purchase Failed', ApiService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('Buy Gift Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          const Text('Purchase a gift card using your wallet balance.'),
          const SizedBox(height: 20),
          AppTextField(
            controller: _amountController,
            hint: 'Amount (₦)',
            keyboardType: TextInputType.number,
            icon: Icons.card_giftcard,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Purchase',
            isLoading: _isLoading,
            onPressed: _onPurchasePressed,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
