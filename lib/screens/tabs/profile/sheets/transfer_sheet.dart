import 'package:flutter/material.dart';
import 'package:campuschow/repositories/wallet_repository.dart';
import 'package:campuschow/screens/auth/widgets/apptextfield.dart';
import 'package:campuschow/screens/auth/widgets/custom_button.dart';
import 'package:campuschow/utils/ui_utils.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/providers/auth_provider.dart';

class TransferSheet extends StatefulWidget {
  const TransferSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TransferSheet(),
    );
  }

  @override
  State<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<TransferSheet> {
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _transfer() async {
    if (_emailController.text.isEmpty || _amountController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await WalletRepository().transferFunds(
        _emailController.text.trim(),
        double.parse(_amountController.text),
      );
      if (!mounted) return;
      context.read<AuthProvider>().refreshUser();
      Navigator.pop(context);
      UIUtils.showSuccessDialog(context, 'Success', 'Transfer successful');
    } catch (e) {
      UIUtils.showErrorDialog(context, 'Transfer Failed', e.toString());
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
          const Text('Transfer Funds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AppTextField(controller: _emailController, hint: 'Recipient Email', icon: Icons.email_outlined),
          const SizedBox(height: 10),
          AppTextField(controller: _amountController, hint: 'Amount', keyboardType: TextInputType.number, icon: Icons.money),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Transfer',
            isLoading: _isLoading,
            onPressed: _transfer,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
