import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;
  bool _isChecking = false;

  void startMonitoring() {
    _timer?.cancel();
    _checkConnection();
    // Check every 8 seconds for real-world internet availability.
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _checkConnection();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  void setOffline() {
    if (_isOnline) {
      _isOnline = false;
      _controller.add(false);
      debugPrint('[NetworkService] Forcefully marked OFFLINE (request failure)');
    }
  }

  void setOnline() {
    if (!_isOnline) {
      _isOnline = true;
      _controller.add(true);
      debugPrint('[NetworkService] Forcefully marked ONLINE');
    }
  }

  Future<bool> checkNow() async {
    return await _checkConnection();
  }

  Future<bool> _checkConnection() async {
    if (_isChecking) return _isOnline;
    _isChecking = true;

    bool previous = _isOnline;
    bool currentOnline = false;

    try {
      // Lookup google.com or apple.com to verify active internet routing.
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      currentOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final result = await InternetAddress.lookup('apple.com')
            .timeout(const Duration(seconds: 3));
        currentOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        currentOnline = false;
      }
    }

    _isChecking = false;
    _isOnline = currentOnline;

    if (previous != _isOnline) {
      _controller.add(_isOnline);
      debugPrint('[NetworkService] Status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    }

    return _isOnline;
  }
}
