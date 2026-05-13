import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Describes the outcome of a payment verification call.
enum PaymentType { orderPayment, walletTopUp, unknown }

class PaymentResult {
  final bool success;
  final PaymentType type;
  final String? orderId;
  final String? message;
  final String? error;
  final bool alreadyProcessed;
  final double? walletBalance;

  const PaymentResult({
    required this.success,
    required this.type,
    this.orderId,
    this.message,
    this.error,
    this.alreadyProcessed = false,
    this.walletBalance,
  });

  bool get isOrderPayment => type == PaymentType.orderPayment;
  bool get isWalletTopUp  => type == PaymentType.walletTopUp;
}

class PaymentService {
  /// Calls the backend `/api/payments/verify` endpoint.
  ///
  /// [reference]  — Paystack transaction reference extracted from deep link.
  /// [orderId]    — MongoDB Order ID extracted from the deep link (may be null
  ///                for wallet top-ups where the backend reads it from metadata).
  ///
  /// Returns a [PaymentResult] describing the outcome.
  /// Never throws — all errors are captured in [PaymentResult.error].
  static Future<PaymentResult> verify({
    required String reference,
    String? orderId,
  }) async {
    try {
      debugPrint('[PaymentService] verify: ref=$reference, orderId=$orderId');

      final response = await apiService.dio.post(
        '/payments/verify',
        data: {
          'reference': reference,
          'orderId': ?orderId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final rawType = data['type'] as String? ?? '';

      PaymentType type;
      switch (rawType) {
        case 'wallet_topup':
          type = PaymentType.walletTopUp;
          break;
        case 'order_payment':
          type = PaymentType.orderPayment;
          break;
        default:
          type = PaymentType.unknown;
      }

      return PaymentResult(
        success:          data['success'] == true,
        type:             type,
        orderId:          data['orderId'] as String?,
        message:          data['message'] as String?,
        alreadyProcessed: data['alreadyProcessed'] == true,
        walletBalance:    (data['walletBalance'] as num?)?.toDouble(),
      );
    } catch (e) {
      final msg = ApiService.getErrorMessage(e);
      debugPrint('[PaymentService] verify error: $msg');
      return PaymentResult(
        success: false,
        type:    PaymentType.unknown,
        error:   msg,
      );
    }
  }
}
