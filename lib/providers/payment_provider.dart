import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../repositories/payment_repository.dart';
import '../locator.dart';
import '../services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  List<TransactionItem> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionItem> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTransactions({String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await locator<PaymentRepository>().getTransactions(type: type);
    } catch (e) {
      _error = ApiService.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
