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

  Future<String> topUp(double amount) async {
    final response = await apiService.dio.post('/payments/topup', data: {
      'amount': amount,
      'source': 'mobile',
    });
    final authorizationUrl = (response.data?['data'] as Map?)?['authorization_url'] as String?;
    if (authorizationUrl == null) throw Exception('Payment initiation failed');
    return authorizationUrl;
  }
}
