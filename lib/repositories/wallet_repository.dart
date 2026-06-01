import '../services/api_service.dart';

class WalletRepository {
  Future<void> transferFunds(String email, double amount) async {
    await apiService.dio.post('/wallet/transfer', data: {
      'recipientEmail': email,
      'amount': amount,
    });
  }

  Future<void> redeemGiftCard(String code) async {
    await apiService.dio.post('/wallet/redeem-gift-card', data: {
      'giftCardCode': code,
    });
  }
}
