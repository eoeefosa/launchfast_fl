import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class TopUpSheet extends StatefulWidget {
  final double initialAmount;

  const TopUpSheet({super.key, this.initialAmount = 1000});

  static Future<void> show(BuildContext context, {double initialAmount = 1000}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => TopUpSheet(initialAmount: initialAmount),
    );
  }

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  late final TextEditingController _amountCtrl;
  bool _isLoading = false;

  static const _quickAmounts = [1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(0),
    );
  }

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
      final response = await apiService.dio.post(
        '/payments/topup',
        data: {
          'amount': amt,
        },
      );

      final paystackData = response.data['data'] as Map<String, dynamic>?;
      final authorizationUrl = paystackData?['authorization_url'] as String?;

      if (authorizationUrl == null) {
        throw Exception('No authorization URL returned from server');
      }

      final uri = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(uri)) {
        if (mounted) Navigator.pop(context);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          await context.read<AuthProvider>().refreshUser();
        }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top Up Wallet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.black87,
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
                    labelStyle: const TextStyle(
                      color: Colors.black45,
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
                      fontSize: 22,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.04),
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
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),

                // Quick chips
                Row(
                  children: _quickAmounts
                      .map(
                        (amt) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _amountCtrl.text = amt.toString(),
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: _amountCtrl.text == amt.toString()
                                      ? scheme.primary.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.04),
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
                                          : Colors.black54,
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
                  children: const [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: Colors.black38,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Secured by Paystack',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Deposit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _deposit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Deposit via Paystack',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 180.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }
}
