import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class TopUpSheet extends StatefulWidget {
  final double initialAmount;

  const TopUpSheet({super.key, this.initialAmount = 1000});

  static Future<void> show(
    BuildContext context, {
    double initialAmount = 1000,
  }) {
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

  double? get _parsedAmount => double.tryParse(_amountCtrl.text.trim());
  bool get _hasValidAmount => (_parsedAmount ?? 0) > 0;

  double get _feeAmount {
    if (_parsedAmount == null) return 0;
    double fee = _parsedAmount! * 0.025;
    if (fee > 2000) fee = 2000;
    return fee;
  }

  double get _totalCharge => (_parsedAmount ?? 0) + _feeAmount;

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
        data: {'amount': amt, 'source': 'mobile'},
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
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopUpHeader(),
                const SizedBox(height: 24),
                _AmountInputField(
                  controller: _amountCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _QuickAmountChips(
                  selectedAmount: _amountCtrl.text,
                  onAmountSelected: (amt) =>
                      setState(() => _amountCtrl.text = amt),
                ),
                const SizedBox(height: 12),
                const _SecurityBadge(),
                if (_hasValidAmount) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount to Deposit',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              '₦${_parsedAmount?.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Processing Fee (2.5%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              '₦${_feeAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Charge',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              '₦${_totalCharge.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _DepositButton(
                  isLoading: _isLoading,
                  onPressed: _deposit,
                  label: _hasValidAmount
                      ? 'Pay ₦${_totalCharge.toStringAsFixed(0)}'
                      : 'Deposit via Paystack',
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

class _TopUpHeader extends StatelessWidget {
  const _TopUpHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
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
            child: Icon(Icons.close_rounded, size: 20, color: scheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class _AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AmountInputField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Enter Amount',
        labelStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
        hintText: '0',
        prefixText: '₦ ',
        prefixStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 22,
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus: true,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: scheme.onSurface,
        letterSpacing: -1,
      ),
    );
  }
}

class _QuickAmountChips extends StatelessWidget {
  final String selectedAmount;
  final ValueChanged<String> onAmountSelected;

  const _QuickAmountChips({
    required this.selectedAmount,
    required this.onAmountSelected,
  });

  static const _quickAmounts = [1000, 2000, 5000];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: _quickAmounts
          .map(
            (amt) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onAmountSelected(amt.toString()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: selectedAmount == amt.toString()
                          ? scheme.primary.withValues(alpha: 0.1)
                          : (isDark
                                ? scheme.surfaceContainerHighest
                                : Colors.black.withValues(alpha: 0.04)),
                      border: Border.all(
                        color: selectedAmount == amt.toString()
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
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: selectedAmount == amt.toString()
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
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DepositButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  const _DepositButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}
