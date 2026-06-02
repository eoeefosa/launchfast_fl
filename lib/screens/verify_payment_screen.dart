import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/payment_service.dart';

enum _VerifyState { idle, loading, success, failed }

class VerifyPaymentScreen extends StatefulWidget {
  const VerifyPaymentScreen({super.key});

  @override
  State<VerifyPaymentScreen> createState() => _VerifyPaymentScreenState();
}

class _VerifyPaymentScreenState extends State<VerifyPaymentScreen> {
  final _referenceCtrl = TextEditingController();
  final _orderIdCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _VerifyState _state = _VerifyState.idle;
  PaymentResult? _result;
  String _errorMsg = '';

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _orderIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _state = _VerifyState.loading;
      _errorMsg = '';
      _result = null;
    });

    final result = await PaymentService.verify(
      reference: _referenceCtrl.text.trim(),
      orderId: _orderIdCtrl.text.trim().isEmpty
          ? null
          : _orderIdCtrl.text.trim(),
    );

    if (!mounted) return;

    if (result.success) {
      HapticFeedback.heavyImpact();
      setState(() {
        _result = result;
        _state = _VerifyState.success;
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorMsg = result.error ?? 'Could not verify this reference.';
        _state = _VerifyState.failed;
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _VerifyState.idle;
      _result = null;
      _errorMsg = '';
    });
  }

  void _navigate() {
    if (_result == null) return;
    if (_result!.isWalletTopUp) {
      context.go('/profile');
    } else if (_result!.orderId != null) {
      context.go('/orders/${_result!.orderId}');
    } else {
      context.go('/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Payment'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: switch (_state) {
              _VerifyState.idle || _VerifyState.loading => _buildForm(scheme),
              _VerifyState.success => _buildSuccess(scheme),
              _VerifyState.failed => _buildFailed(scheme),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme scheme) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: scheme.primary, size: 28),
                const SizedBox(height: 10),
                Text(
                  'Payment shows as failed?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'If your bank was debited but your order is still unpaid, '
                  'enter your Paystack reference below to verify manually.',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 28),

          // Reference field
          Text(
            'Payment Reference',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _referenceCtrl,
            enabled: _state != _VerifyState.loading,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. T123456789',
              prefixIcon: const Icon(Icons.tag_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Reference is required' : null,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 6),
          Text(
            'Find this in your Paystack receipt email or bank SMS.',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),

          const SizedBox(height: 20),

          // Order ID field
          Text(
            'Order ID (optional)',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _orderIdCtrl,
            enabled: _state != _VerifyState.loading,
            decoration: InputDecoration(
              hintText: 'Leave blank for wallet top-ups',
              prefixIcon: const Icon(Icons.receipt_long_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _state == _VerifyState.loading ? null : _verify,
              icon: _state == _VerifyState.loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                _state == _VerifyState.loading
                    ? 'Verifying…'
                    : 'Verify Payment',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildSuccess(ColorScheme scheme) {
    final res = _result!;
    return Column(
      key: const ValueKey('success'),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 72,
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          res.alreadyProcessed ? 'Already Verified' : 'Payment Verified!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 10),
        Text(
          res.message ??
              (res.isWalletTopUp
                  ? 'Your wallet has been credited.'
                  : 'Your order payment has been confirmed.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: scheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms),
        if (res.isWalletTopUp && res.walletBalance != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Balance: ₦${res.walletBalance!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _navigate,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              res.isWalletTopUp ? 'View Wallet' : 'View My Orders',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _reset,
          child: const Text('Verify Another Reference'),
        ).animate().fadeIn(delay: 450.ms),
      ],
    );
  }

  Widget _buildFailed(ColorScheme scheme) {
    return Column(
      key: const ValueKey('failed'),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 72,
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          'Verification Failed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 10),
        Text(
          _errorMsg,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: scheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 10),
        Text(
          'If you were charged, funds will be refunded within 5–7 business days.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.45),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/orders'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'My Orders',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _reset,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
      ],
    );
  }
}
