import 'package:flutter/material.dart';
import 'package:campuschow/services/ably_service.dart';

/// Provider for Rider-specific job management.
class RiderJobProvider with ChangeNotifier {
  bool _isAvailable = true;
  String? _currentJobId;

  bool get isAvailable => _isAvailable;
  String? get currentJobId => _currentJobId;

  RiderJobProvider() {
    _initRiderListeners();
  }

  void _initRiderListeners() {
    // Listen for job assignments
    ablyService.addNotificationListener((payload) {
      if (payload['type'] == 'new_job') {
        debugPrint('[RiderJobProvider] New job received: ${payload['orderId']}');
        // Logic to alert the UI or trigger a push notification goes here.
        notifyListeners();
      }
    });
  }

  void toggleAvailability(bool status) {
    _isAvailable = status;
    notifyListeners();
    // API call to update rider status...
  }
}
