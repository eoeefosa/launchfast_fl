import '../../../providers/cart_provider.dart';

class CheckoutState {
  final DeliveryType deliveryType;
  final String paymentMethod;
  final bool isSuccess;

  CheckoutState({
    this.deliveryType = DeliveryType.bulk,
    this.paymentMethod = 'Wallet',
    this.isSuccess = false,
  });

  CheckoutState copyWith({
    DeliveryType? deliveryType,
    String? paymentMethod,
    bool? isSuccess,
  }) {
    return CheckoutState(
      deliveryType: deliveryType ?? this.deliveryType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
