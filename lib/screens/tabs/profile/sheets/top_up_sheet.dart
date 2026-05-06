import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _deposit() async {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Initialize Paystack top-up transaction
      final response = await apiService.dio.post(
        '/payments/topup',
        data: {'amount': amt},
      );

      final data = response.data;
      // Paystack wraps result in a 'data' key
      final paystackData = data['data'] as Map<String, dynamic>?;
      final authorizationUrl = paystackData?['authorization_url'] as String?;

      if (authorizationUrl == null) {
        throw Exception('No authorization URL returned from server');
      }

      final uri = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(uri)) {
        if (mounted) Navigator.pop(context); // close sheet before opening browser
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // After returning from browser, refresh user balance
        await widget.auth.refreshUser();
      } else {
        throw Exception('Could not open payment portal');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            onChanged: (_) => setState(() {}), // rebuild to update chip border
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
                          onTap: () =>
                              setState(() => _amountCtrl.text = amt.toString()),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: scheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  'Secured by Paystack',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          CustomButton(
            isLoading: _isLoading,
            label: 'Deposit via Paystack',
            primaryColor: scheme.primary,
            onPressed: _isLoading ? null : _deposit,
          ),
        ],
      ),
    );
  }
}
