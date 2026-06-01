import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/wallet_repository.dart';
import '../../../../services/api_service.dart';
import '../../../../utils/ui_utils.dart';
import '../../../auth/widgets/apptextfield.dart';
import '../../../auth/widgets/custom_button.dart';

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

  Future<void> _buyGiftCard() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final auth = context.read<AuthProvider>();
    if ((auth.user?.walletBalance ?? 0) < amount) {
      UIUtils.showErrorDialog(context, 'Insufficient Balance', 'You do not have enough funds in your wallet.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await WalletRepository().buyGiftCard(amount);
      if (!mounted) return;
      await auth.refreshUser();
      Navigator.pop(context);
      UIUtils.showSuccessDialog(
        context,
        'Success',
        'Gift card purchased successfully! The code has been sent to your email.',
      );
    } catch (e) {
      UIUtils.showErrorDialog(context, 'Purchase Failed', ApiService.getErrorMessage(e));
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
            onPressed: _buyGiftCard,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
