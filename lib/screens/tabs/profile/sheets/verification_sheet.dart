import 'package:flutter/material.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../auth/widgets/constants.dart';
import '../../../auth/widgets/custom_button.dart';
import '../widgets/bottom_sheet_scaffold.dart';

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
    switch (_predictedNetwork) {
      case 'MTN':
        return Colors.yellow.shade100;
      case 'Glo':
        return Colors.green.shade100;
      case 'Airtel':
        return Colors.red.shade100;
      case '9mobile':
        return Colors.orange.shade200;
      default:
        return Colors.white;
    }
  }

  Color get _titleColor {
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
    final title = _isPhone ? 'Verify Phone via Telegram' : 'Verify Email';

    return BottomSheetScaffold(
      title: title,
      backgroundColor: _networkColor,
      textColor: _titleColor,
      child: _codeSent ? _buildOtpStep() : _buildSendStep(context),
    );
  }

  Widget _buildSendStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isPhone) ...[
          Text(
            'To receive your OTP, please enter your Nigerian Phone Number.',
            style: TextStyle(color: _subtitleColor, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(color: _subtitleColor),
              hintText: 'e.g. 0803 123 4567',
              hintStyle: TextStyle(
                color: _subtitleColor.withValues(alpha: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _subtitleColor.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _titleColor, width: 2),
              ),
              suffixIcon: SizedBox(
                width: 60,
                child: Center(
                  child: _predictedNetwork.isNotEmpty
                      ? Text(
                          _predictedNetwork,
                          style: TextStyle(
                            color: _titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 11,
          ),
        ] else
          Text(
            'We will send a 6-digit OTP to ${widget.auth.user!.email}.',
            style: TextStyle(color: _subtitleColor, fontSize: 14),
          ),
        const SizedBox(height: 20),
        CustomButton(
          primaryColor: Theme.of(context).primaryColor,
          label: 'Send Code',
          onPressed: _isSending ? null : _sendCode,
          isLoading: _isSending,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the 6-digit code you received.',
          style: TextStyle(color: _subtitleColor, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otpCtrl,
          style: TextStyle(
            color: _titleColor,
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'OTP Code',
            labelStyle: TextStyle(color: _subtitleColor),
            hintText: '123456',
            hintStyle: TextStyle(color: _subtitleColor.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _subtitleColor.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _titleColor, width: 2),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        CustomButton(
          primaryColor: Theme.of(context).primaryColor,
          isLoading: _isVerifying,
          label: 'Verify Now',
          onPressed: _isVerifying ? null : _verifyOtp,
        ),
      ],
    );
  }
}
