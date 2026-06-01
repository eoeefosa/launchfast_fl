import 'package:campuschow/screens/auth/widgets/apptextfield.dart';
import 'package:campuschow/screens/auth/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/wallet_repository.dart';
import '../../../../services/api_service.dart';
import '../../../../utils/ui_utils.dart';

class BuyGiftCardScreen extends StatefulWidget {
  const BuyGiftCardScreen({super.key});

  @override
  State<BuyGiftCardScreen> createState() => _BuyGiftCardScreenState();
}

class _BuyGiftCardScreenState extends State<BuyGiftCardScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _buyGiftCard() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      UIUtils.showErrorDialog(context, 'Error', 'Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      UIUtils.showErrorDialog(context, 'Error', 'Please enter a valid amount');
      return;
    }

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
      UIUtils.showSuccessDialog(
        context,
        'Success',
        'Gift card purchased successfully! The code has been sent to your email.',
      );
      _amountController.clear();
    } catch (e) {
      UIUtils.showErrorDialog(context, 'Purchase Failed', ApiService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('Buy Gift Card', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchase a gift card using your wallet balance.',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightMuted,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Amount (₦)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: textColor,
              ),
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _amountController,
              hint: 'Enter amount (e.g. 5000)',
              keyboardType: TextInputType.number,
              icon: Icons.card_giftcard,
            ),
            SizedBox(height: 40.h),
            CustomButton(
              label: 'Purchase Gift Card',
              isLoading: _isLoading,
              onPressed: _buyGiftCard,
              primaryColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
