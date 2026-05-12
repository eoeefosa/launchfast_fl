import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/payment_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

/// Displayed when the user is redirected back from the Paystack payment page
/// via the deep link: campuschow://payment/callback?reference=REF&orderId=ID&type=TYPE
///
/// Responsibilities:
///   1. Show an immediate loading state ("Verifying payment…")
///   2. Call the backend verify endpoint
///   3. Navigate to the correct screen based on the result
///   4. Handle all error states gracefully
class PaymentCallbackScreen extends StatefulWidget {
  /// Paystack transaction reference — required.
  final String reference;

  /// MongoDB order ID — null for wallet top-ups.
  final String? orderId;

  /// Paystack payment type hint from the deep-link URL.
  final String? type;

  const PaymentCallbackScreen({
    super.key,
    required this.reference,
    this.orderId,
    this.type,
  });

  @override
  State<PaymentCallbackScreen> createState() => _PaymentCallbackScreenState();
}

class _PaymentCallbackScreenState extends State<PaymentCallbackScreen> {
  _ScreenState _state = _ScreenState.loading;
  String _statusMessage = 'Verifying your payment…';
  String? _errorMessage;
  PaymentResult? _result;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      final result = await PaymentService.verify(
        reference: widget.reference,
        orderId: widget.orderId,
      );

      if (!mounted) return;

      if (result.success) {
        HapticFeedback.heavyImpact();
        setState(() {
          _result = result;
          _state = _ScreenState.success;
          _statusMessage = result.message ?? 'Payment successful!';
        });

        // Refresh data in the background
        final auth = context.read<AuthProvider>();
        final orders = context.read<OrderProvider>();
        if (result.isWalletTopUp) {
          await auth.refreshUser();
        } else {
          await orders.refreshOrders();
        }

        // Auto-navigate after 2 seconds so the user sees the success state
        if (mounted) {
          await Future.delayed(const Duration(seconds: 2));
          _navigate(result);
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _state = _ScreenState.failed;
          _errorMessage = result.error ?? 'Payment could not be verified.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.failed;
        _errorMessage = 'Unexpected error. Please check your orders.';
      });
    }
  }

  void _navigate(PaymentResult result) {
    if (!mounted) return;

    if (result.isWalletTopUp) {
      // Wallet top-up: go to profile so they can see the new balance
      context.go('/profile');
    } else if (result.orderId != null) {
      // Order payment: go to the orders list
      context.go('/orders');
    } else {
      // Fallback
      context.go('/home');
    }
  }

  void _retry() {
    setState(() {
      _state = _ScreenState.loading;
      _statusMessage = 'Verifying your payment…';
      _errorMessage = null;
    });
    _verify();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
              child: switch (_state) {
                _ScreenState.loading => _LoadingView(
                    key: const ValueKey('loading'),
                    message: _statusMessage,
                    scheme: scheme,
                  ),
                _ScreenState.success => _SuccessView(
                    key: const ValueKey('success'),
                    message: _statusMessage,
                    result: _result,
                    scheme: scheme,
                    onNavigate: () => _navigate(_result!),
                  ),
                _ScreenState.failed => _FailedView(
                    key: const ValueKey('failed'),
                    message: _errorMessage ?? 'Payment verification failed.',
                    scheme: scheme,
                    onRetry: _retry,
                    onGoHome: () => context.go('/orders'),
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum _ScreenState { loading, success, failed }

// ── Loading ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final String message;
  final ColorScheme scheme;

  const _LoadingView({super.key, required this.message, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please do not close the app.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Success ──────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String message;
  final PaymentResult? result;
  final ColorScheme scheme;
  final VoidCallback onNavigate;

  const _SuccessView({
    super.key,
    required this.message,
    required this.result,
    required this.scheme,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 72),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 28),
        Text(
          'Payment Confirmed!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: scheme.onSurface,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: scheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 300.ms),
        if (result?.isWalletTopUp == true && result?.walletBalance != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'New balance: ₦${result!.walletBalance!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: onNavigate,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              result?.isWalletTopUp == true ? 'View Wallet' : 'View My Orders',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
      ],
    );
  }
}

// ── Failed ───────────────────────────────────────────────────────────────────

class _FailedView extends StatelessWidget {
  final String message;
  final ColorScheme scheme;
  final VoidCallback onRetry;
  final VoidCallback onGoHome;

  const _FailedView({
    super.key,
    required this.message,
    required this.scheme,
    required this.onRetry,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 72),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 28),
        Text(
          'Verification Failed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: scheme.onSurface,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: scheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 12),
        Text(
          'If your payment was debited, it will be automatically refunded within 5–7 business days.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.45),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onGoHome,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
      ],
    );
  }
}
