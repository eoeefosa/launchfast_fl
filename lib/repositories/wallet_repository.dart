import '../services/api_service.dart';

class WalletRepository {
  Future<Map<String, dynamic>> lookupUser(String email) async {
    final response = await apiService.dio.get('/users/lookup', queryParameters: {
      'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

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

  Future<void> buyGiftCard(double amount) async {
    await apiService.dio.post('/wallet/buy-gift-card', data: {
      'amount': amount,
    });
  }
}
