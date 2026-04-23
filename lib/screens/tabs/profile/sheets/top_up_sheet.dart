import 'package:flutter/material.dart';
import '../../../../providers/auth_provider.dart';
import '../../../auth/widgets/custom_button.dart';
import '../widgets/bottom_sheet_scaffold.dart';

class TopUpSheet extends StatefulWidget {
  const TopUpSheet({super.key, required this.auth});

  final AuthProvider auth;

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  final _amountCtrl = TextEditingController();
  static const _quickAmounts = [1000, 2000, 5000];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _deposit() {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) return;
    widget.auth.topUpWallet(amt);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('₦${amt.toStringAsFixed(2)} added to wallet!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      title: 'Top Up Wallet',
      child: Column(
        children: [
          TextField(
            controller: _amountCtrl,
            decoration: InputDecoration(
              labelText: 'Enter Amount',
              hintText: '0.00',
              prefixText: '₦ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(20),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: _quickAmounts
                .map(
                  (amt) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _amountCtrl.text = amt.toString()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('₦$amt', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          CustomButton(
            isLoading: widget.auth.isLoading,
            label: 'Deposit Now',
            primaryColor: Theme.of(context).primaryColor,
            onPressed: widget.auth.isLoading ? null : _deposit,
          ),
        ],
      ),
    );
  }
}
