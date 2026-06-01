import 'package:flutter/material.dart';
import 'package:campuschow/repositories/wallet_repository.dart';
import 'package:campuschow/screens/auth/widgets/apptextfield.dart';
import 'package:campuschow/screens/auth/widgets/custom_button.dart';
import 'package:campuschow/utils/ui_utils.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/providers/auth_provider.dart';

class RedeemSheet extends StatefulWidget {
  const RedeemSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const RedeemSheet(),
    );
  }

  @override
  State<RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends State<RedeemSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _redeem() async {
    if (_codeController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await WalletRepository().redeemGiftCard(_codeController.text.trim());
      if (!mounted) return;
      context.read<AuthProvider>().refreshUser();
      Navigator.pop(context);
      UIUtils.showSuccessDialog(context, 'Success', 'Gift card redeemed');
    } catch (e) {
      UIUtils.showErrorDialog(context, 'Redemption Failed', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Redeem Gift Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          AppTextField(controller: _codeController, hint: 'Gift Card Code', icon: Icons.card_giftcard),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Redeem',
            isLoading: _isLoading,
            onPressed: _redeem,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
