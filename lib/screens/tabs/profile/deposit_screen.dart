import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/wallet_repository.dart';
import '../../../services/api_service.dart';
import '../../../utils/ui_utils.dart';
import '../../auth/widgets/apptextfield.dart';
import '../../auth/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _deposit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final authorizationUrl = await WalletRepository().topUp(amount);
      final uri = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) UIUtils.showErrorDialog(context, 'Deposit Failed', ApiService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit Funds')),
      body: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            AppTextField(
              controller: _amountController,
              hint: 'Amount (₦)',
              keyboardType: TextInputType.number,
              icon: Icons.wallet_rounded,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              label: 'Deposit',
              isLoading: _isLoading,
              onPressed: _deposit,
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
