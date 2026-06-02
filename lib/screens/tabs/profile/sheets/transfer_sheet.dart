import 'dart:async';
import 'package:flutter/material.dart';
import 'package:campuschow/repositories/wallet_repository.dart';
import 'package:campuschow/screens/auth/widgets/apptextfield.dart';
import 'package:campuschow/screens/auth/widgets/custom_button.dart';
import 'package:campuschow/services/api_service.dart';
import 'package:campuschow/store/pages/core/services/notification_service.dart';
import 'package:campuschow/utils/ui_utils.dart';
import 'package:campuschow/widgets/pin_entry_sheet.dart';
import 'package:campuschow/widgets/set_pin_sheet.dart';
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
  String? _recipientName;
  String? _lookupError;
  bool _isLookingUp = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _amountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onEmailChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final email = _emailController.text.trim();
      if (email.contains('@') && email.contains('.')) {
        _lookupUser(email);
      } else {
        if (mounted) setState(() { _recipientName = null; _lookupError = null; });
      }
    });
  }

  Future<void> _lookupUser(String email) async {
    if (_isLookingUp) return;
    setState(() => _isLookingUp = true);
    try {
      final user = await WalletRepository().lookupUser(email);
      if (mounted) {
        setState(() {
          _recipientName = user['name'];
          _lookupError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recipientName = null;
          _lookupError = ApiService.getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  Future<void> _onTransferPressed() async {
    if (_emailController.text.isEmpty || _amountController.text.isEmpty) return;

    final auth = context.read<AuthProvider>();

    // Ensure PIN is set first
    if (!(auth.user?.hasTransactionPin ?? false)) {
      final pinSet = await SetPinSheet.show(context);
      if (!mounted || !pinSet) return;
    }

    // Verify PIN before proceeding
    final confirmed = await PinEntrySheet.show(
      context,
      title: 'Enter Transaction PIN',
      onSubmit: (pin) => WalletRepository().verifyTransactionPin(pin),
    );
    if (!mounted || !confirmed) return;

    _transfer(auth);
  }

  Future<void> _transfer(AuthProvider auth) async {
    setState(() => _isLoading = true);
    final amount = double.parse(_amountController.text);
    final recipient = _emailController.text.trim();
    try {
      final newBalance = await WalletRepository().transferFunds(recipient, amount);
      if (!mounted) return;

      // Update balance in real time
      if (newBalance != null) {
        auth.updateWalletBalance(newBalance);
      } else {
        auth.refreshUser();
      }

      // Local notification
      notificationService.showNotification(
        title: 'Transfer Successful',
        body: 'You sent ₦${amount.toStringAsFixed(2)} to ${_recipientName ?? recipient}.',
        payload: 'wallet_transfer',
      );

      Navigator.pop(context);
      UIUtils.showSuccessDialog(context, 'Success', 'Transfer successful');
    } catch (e) {
      if (mounted) UIUtils.showErrorDialog(context, 'Transfer Failed', ApiService.getErrorMessage(e));
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('Transfer Funds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          AppTextField(controller: _emailController, hint: 'Recipient Email', icon: Icons.email_outlined),
          if (_isLookingUp)
            const Padding(
              padding: EdgeInsets.only(top: 8.0, left: 12.0),
              child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_recipientName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                'Recipient: $_recipientName',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            )
          else if (_lookupError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(_lookupError!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 10),
          AppTextField(controller: _amountController, hint: 'Amount', keyboardType: TextInputType.number, icon: Icons.money),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Transfer',
            isLoading: _isLoading,
            onPressed: _onTransferPressed,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
