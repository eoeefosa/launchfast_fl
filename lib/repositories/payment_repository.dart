import '../services/api_service.dart';
import '../models/transaction.dart';

class PaymentRepository {
  Future<List<TransactionItem>> getTransactions({String? type, int limit = 50}) async {
    final response = await apiService.dio.get(
      '/payments/transactions',
      queryParameters: {
        if (type != null) 'type': type,
        'limit': limit,
      },
    );

    if (response.data is! Map || response.data['transactions'] is! List) {
      throw FormatException('Invalid response from /payments/transactions');
    }

    final List list = response.data['transactions'];
    return list.map((json) => TransactionItem.fromJson(json)).toList();
  }
}
