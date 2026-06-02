import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constants/app_colors.dart';
import 'sheets/redeem_sheet.dart';

class RedeemGiftCardScreen extends StatelessWidget {
  const RedeemGiftCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: const Text('Redeem Gift Card', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: textColor,
          systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        ),
        body: const SingleChildScrollView(
          child: RedeemSheet(),
        ),
      ),
    );
  }
}
