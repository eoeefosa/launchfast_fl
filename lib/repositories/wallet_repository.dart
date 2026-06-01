import '../services/api_service.dart';

class WalletRepository {
  Future<Map<String, dynamic>> lookupUser(String email) async {
    final response = await apiService.dio.get('/users/lookup', queryParameters: {
      'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Returns the sender's new wallet balance after transfer.
  Future<double?> transferFunds(String email, double amount) async {
    final res = await apiService.dio.post('/wallet/transfer', data: {
      'recipientEmail': email,
      'amount': amount,
    });
    return (res.data?['newBalance'] as num?)?.toDouble();
  }

  /// Returns the user's new wallet balance after redemption.
  Future<double?> redeemGiftCard(String code) async {
    final res = await apiService.dio.post('/wallet/redeem-gift-card', data: {
      'giftCardCode': code,
    });
    return (res.data?['newBalance'] as num?)?.toDouble();
  }

  /// Returns the user's new wallet balance after purchase.
  Future<double?> buyGiftCard(double amount) async {
    final res = await apiService.dio.post('/wallet/buy-gift-card', data: {
      'amount': amount,
    });
    return (res.data?['newBalance'] as num?)?.toDouble();
  }

  Future<void> setTransactionPin(String pin) async {
    await apiService.dio.post('/wallet/set-pin', data: {'pin': pin});
  }

  Future<void> verifyTransactionPin(String pin) async {
    await apiService.dio.post('/wallet/verify-pin', data: {'pin': pin});
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
