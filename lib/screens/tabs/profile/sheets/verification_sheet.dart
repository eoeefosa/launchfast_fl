import 'package:flutter/material.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../auth/widgets/constants.dart';
import '../../../auth/widgets/custom_button.dart';

class VerificationSheet extends StatefulWidget {
  const VerificationSheet({
    super.key,
    required this.auth,
    required this.method,
  });

  final AuthProvider auth;
  final String method;

  @override
  State<VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<VerificationSheet> {
  final _otpCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isSending = false;
  bool _codeSent = false;
  bool _isVerifying = false;

  String _predictedNetwork = '';

  bool get _isPhone => widget.method == 'phone';

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_predictNetwork);
  }

  void _predictNetwork() {
    final text = _phoneCtrl.text;
    if (text.length >= 4) {
      final prefix = text.substring(0, 4);
      for (final network in networks) {
        if ((network['prefix'] as List).contains(prefix)) {
          if (_predictedNetwork != network['name']) {
            setState(() {
              _predictedNetwork = network['name'] as String;
            });
          }
          return;
        }
      }
    }
    if (_predictedNetwork.isNotEmpty) {
      setState(() {
        _predictedNetwork = '';
      });
    }
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _isSending = true);
    try {
      await apiService.dio.post(
        '/auth/send-verification',
        data: {
          'method': widget.method,
          if (_isPhone) 'phoneNumber': _phoneCtrl.text.trim(),
        },
      );
      setState(() => _codeSent = true);
    } catch (_) {
      _showSnackBar('Failed to send code. Check details and try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isVerifying = true);
    try {
      await apiService.dio.post(
        '/auth/verify',
        data: {'method': widget.method, 'otp': _otpCtrl.text.trim()},
      );
      await widget.auth.refreshUser();
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Verified successfully!', success: true);
      }
    } catch (_) {
      _showSnackBar(
        'Invalid or expired OTP. Please try again.',
        success: false,
      );
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color get _networkColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      switch (_predictedNetwork) {
        case 'MTN':
          return Colors.yellow.shade50;
        case 'Glo':
          return Colors.green.shade50;
        case 'Airtel':
          return Colors.red.shade50;
        case '9mobile':
          return Colors.orange.shade50;
        default:
          return Colors.white;
      }
    } else {
      // In dark mode, we use the standard surface but with a hint of the network color
      return Theme.of(context).colorScheme.surface;
    }
  }

  Color get _accentColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_predictedNetwork) {
      case 'MTN':
        return isDark ? Colors.yellowAccent.shade700 : Colors.yellow.shade800;
      case 'Glo':
        return isDark ? Colors.greenAccent.shade400 : Colors.green.shade700;
      case 'Airtel':
        return isDark ? Colors.redAccent.shade200 : Colors.red.shade700;
      case '9mobile':
        return isDark ? Colors.orangeAccent.shade400 : Colors.orange.shade800;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color get _titleColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return Theme.of(context).colorScheme.onSurface;

    switch (_predictedNetwork) {
      case 'MTN':
        return Colors.brown.shade900;
      case 'Glo':
        return Colors.green.shade900;
      case 'Airtel':
        return Colors.red.shade900;
      case '9mobile':
        return Colors.orange.shade900;
      default:
        return Colors.black87;
    }
  }

  Color get _subtitleColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    switch (_predictedNetwork) {
      case 'MTN':
        return Colors.brown.shade700;
      case 'Glo':
        return Colors.green.shade700;
      case 'Airtel':
        return Colors.red.shade700;
      case '9mobile':
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final title = _isPhone ? 'Phone Verification' : 'Email Verification';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: _networkColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? scheme.onSurface.withValues(alpha: 0.1) : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _titleColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: _titleColor.withValues(alpha: 0.5)),
                      style: IconButton.styleFrom(
                        backgroundColor: _titleColor.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: isDark && _predictedNetwork.isNotEmpty ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: _accentColor, width: 4),
                    ),
                  ) : null,
                  padding: isDark && _predictedNetwork.isNotEmpty ? const EdgeInsets.only(left: 16) : null,
                  child: _codeSent ? _buildOtpStep() : _buildSendStep(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isPhone) ...[
          Text(
            'Enter your phone number to receive a 6-digit OTP via Telegram or SMS.',
            style: TextStyle(
              color: _subtitleColor, 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneCtrl,
            style: TextStyle(
              color: _titleColor, 
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(
                color: _subtitleColor,
                fontWeight: FontWeight.w600,
              ),
              hintText: '0803 123 4567',
              hintStyle: TextStyle(
                color: _subtitleColor.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: isDark 
                  ? scheme.onSurface.withValues(alpha: 0.05) 
                  : (_predictedNetwork.isNotEmpty ? Colors.white.withValues(alpha: 0.5) : Colors.grey[100]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _accentColor, width: 2),
              ),
              prefixIcon: Icon(Icons.phone_iphone_rounded, color: _accentColor),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_predictedNetwork.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _predictedNetwork,
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 11,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          ),
        ] else
          Text(
            'We will send a 6-digit verification code to your email address: ${widget.auth.user!.email}.',
            style: TextStyle(
              color: _subtitleColor, 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        const SizedBox(height: 32),
        CustomButton(
          primaryColor: _accentColor,
          label: 'Send Verification Code',
          onPressed: _isSending ? null : _sendCode,
          isLoading: _isSending,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A 6-digit code has been sent. Please enter it below to verify.',
          style: TextStyle(
            color: _subtitleColor, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpCtrl,
          style: TextStyle(
            color: _titleColor,
            fontSize: 32,
            letterSpacing: 12,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            labelText: 'Verification Code',
            labelStyle: TextStyle(
              color: _subtitleColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            hintText: '000000',
            hintStyle: TextStyle(
              color: _subtitleColor.withValues(alpha: 0.2),
              letterSpacing: 12,
            ),
            filled: true,
            fillColor: isDark 
                ? scheme.onSurface.withValues(alpha: 0.05) 
                : Colors.white.withValues(alpha: 0.5),
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
              borderSide: BorderSide(color: _accentColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        ),
        const SizedBox(height: 32),
        CustomButton(
          primaryColor: _accentColor,
          isLoading: _isVerifying,
          label: 'Verify & Continue',
          onPressed: _isVerifying ? null : _verifyOtp,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isSending ? null : _sendCode,
            child: Text(
              'Resend Code',
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
