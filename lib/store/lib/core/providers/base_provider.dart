import 'package:flutter/material.dart';
import '../error/failures.dart';

class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  Failure? _failure;

  bool get isLoading => _isLoading;
  Failure? get failure => _failure;
  bool get hasError => _failure != null;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setFailure(Failure? failure) {
    _failure = failure;
    notifyListeners();
  }

  void clearError() {
    _failure = null;
    notifyListeners();
  }
}
