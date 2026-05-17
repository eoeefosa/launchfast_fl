import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../auth/widgets/custom_button.dart';
import '../widgets/bottom_sheet_scaffold.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kQuickAmounts = <int>[1000, 2000, 5000];

// ─────────────────────────────────────────────────────────────────────────────
// TopUpSheet
// ─────────────────────────────────────────────────────────────────────────────

class TopUpSheet extends StatefulWidget {
  const TopUpSheet({super.key, required this.auth});

  final AuthProvider auth;

  /// Convenience launcher — keeps the call-site clean.
  static Future<void> show(BuildContext context, AuthProvider auth) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TopUpSheet(auth: auth),
    );
  }

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final TextEditingController _amountCtrl;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;

  // ── Derived ────────────────────────────────────────────────────────────────
  double? get _parsedAmount => double.tryParse(_amountCtrl.text.trim());
  bool get _hasValidAmount => (_parsedAmount ?? 0) > 0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController()..addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountCtrl
      ..removeListener(_onAmountChanged)
      ..dispose();
    super.dispose();
  }

  // ── Listeners ──────────────────────────────────────────────────────────────

  void _onAmountChanged() => setState(() {});

  // ── Actions ────────────────────────────────────────────────────────────────

  void _selectQuickAmount(int amount) {
    _amountCtrl.text = amount.toString();
    // Move cursor to end.
    _amountCtrl.selection = TextSelection.collapsed(
      offset: _amountCtrl.text.length,
    );
  }

  Future<void> _deposit() async {
    if (!_hasValidAmount) {
      _showSnackBar('Please enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await apiService.dio.post<Map<String, dynamic>>(
        '/payments/topup',
        data: {'amount': _parsedAmount, 'source': 'mobile'},
      );

      final paystackData =
          (response.data?['data']) as Map<String, dynamic>?;
      final authorizationUrl =
          paystackData?['authorization_url'] as String?;

      if (authorizationUrl == null) {
        throw Exception('No authorization URL returned from server');
      }

      final uri = Uri.parse(authorizationUrl);
      if (!await canLaunchUrl(uri)) {
        throw Exception('Could not open payment portal');
      }

      if (mounted) Navigator.pop(context);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      _showSnackBar('Payment failed: $message', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: isError ? SnackBarBehavior.floating : null,
        shape: isError
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            : null,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomSheetScaffold(
      title: 'Top Up Wallet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AmountField(controller: _amountCtrl, scheme: scheme),
          const SizedBox(height: 20),
          _QuickAmountRow(
            amounts: _kQuickAmounts,
            currentText: _amountCtrl.text,
            scheme: scheme,
            isDark: isDark,
            onSelect: _selectQuickAmount,
          ),
          const SizedBox(height: 24),
          _SecurityBadge(scheme: scheme),
          const SizedBox(height: 32),
          CustomButton(
            isLoading: _isLoading,
            label: 'Deposit Funds via Paystack',
            primaryColor: scheme.primary,
            onPressed: _isLoading ? null : _deposit,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AmountField
// ─────────────────────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.scheme});

  final TextEditingController controller;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: scheme.onSurface,
        letterSpacing: -1,
      ),
      decoration: InputDecoration(
        labelText: 'Enter Amount',
        labelStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.6),
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
          fontSize: 24,
        ),
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.all(24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickAmountRow
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAmountRow extends StatelessWidget {
  const _QuickAmountRow({
    required this.amounts,
    required this.currentText,
    required this.scheme,
    required this.isDark,
    required this.onSelect,
  });

  final List<int> amounts;
  final String currentText;
  final ColorScheme scheme;
  final bool isDark;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: amounts
          .map(
            (amt) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _QuickAmountChip(
                  amount: amt,
                  selected: currentText == amt.toString(),
                  scheme: scheme,
                  isDark: isDark,
                  onTap: () => onSelect(amt),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickAmountChip
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({
    required this.amount,
    required this.selected,
    required this.scheme,
    required this.isDark,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.1)
              : (isDark ? scheme.surfaceContainerHighest : Colors.grey[100]),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            '₦$amount',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SecurityBadge
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Text(
              'Secured by Paystack',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}