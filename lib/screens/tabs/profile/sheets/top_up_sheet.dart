import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../auth/widgets/custom_button.dart';

class TopUpSheet extends StatefulWidget {
  const TopUpSheet({super.key, required this.auth});

  final AuthProvider auth;

  static Future<void> show(BuildContext context, AuthProvider auth) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => TopUpSheet(auth: auth),
    );
  }

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

    // Capture platform before async gap
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    setState(() => _isLoading = true);

    try {
      final response = await apiService.dio.post(
        '/payments/topup',
        data: {'amount': amt},
      );

      final data = response.data;
      final paystackData = data['data'] as Map<String, dynamic>?;
      final authorizationUrl = paystackData?['authorization_url'] as String?;

      if (authorizationUrl == null) {
        throw Exception('No authorization URL returned from server');
      }

      final uri = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(uri)) {
        if (mounted) Navigator.pop(context);
        // Use in-app browser on iOS so the campuschow:// deep link can bring the
        // user back after completing payment. Android uses external browser.
        await launchUrl(
          uri,
          mode: isIOS ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication,
        );
        // Deep link (/payment/callback) handles refresh & navigation.
      } else {
        throw Exception('Could not open payment portal');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment failed: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Up Wallet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: scheme.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount input
            TextField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: 'Enter Amount',
                labelStyle: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6),
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
                fillColor: scheme.onSurface.withValues(alpha: 0.04),
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
                contentPadding: const EdgeInsets.all(20),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),

            // Quick amount chips
            Row(
              children: _quickAmounts
                  .map(
                    (amt) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _amountCtrl.text = amt.toString()),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _amountCtrl.text == amt.toString()
                                  ? scheme.primary.withValues(alpha: 0.1)
                                  : scheme.onSurface.withValues(alpha: 0.04),
                              border: Border.all(
                                color: _amountCtrl.text == amt.toString()
                                    ? scheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '₦$amt',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: _amountCtrl.text == amt.toString()
                                      ? scheme.primary
                                      : scheme.onSurface.withValues(alpha: 0.6),
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

            // Security badge
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 5),
                Text(
                  'Secured by Paystack',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Deposit button
            CustomButton(
              isLoading: _isLoading,
              label: 'Deposit via Paystack',
              primaryColor: scheme.primary,
              onPressed: _isLoading ? null : _deposit,
            ),
          ],
        ),
      ),
    );
  }
}
