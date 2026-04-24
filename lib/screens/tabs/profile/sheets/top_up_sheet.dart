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
        content: Text(
          '₦${amt.toStringAsFixed(0)} added to wallet!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BottomSheetScaffold(
      title: 'Top Up Wallet',
      child: Column(
        children: [
          TextField(
            controller: _amountCtrl,
            decoration: InputDecoration(
              labelText: 'Enter Amount',
              labelStyle: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
              floatingLabelStyle: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
              hintText: '0',
              prefixText: '₦ ',
              prefixStyle: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
              filled: true,
              fillColor: scheme.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(24),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: _quickAmounts
                .map(
                  (amt) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: scheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _amountCtrl.text == amt.toString()
                                    ? scheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '₦$amt',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _amountCtrl.text == amt.toString()
                                      ? scheme.primary
                                      : scheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 40),
          CustomButton(
            isLoading: widget.auth.isLoading,
            label: 'Deposit Now',
            primaryColor: scheme.primary,
            onPressed: widget.auth.isLoading ? null : _deposit,
          ),
        ],
      ),
    );
  }
}
