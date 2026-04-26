import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'api_service.dart';
import '../models/order.dart';

/// A focused real-time messaging service backed by Ably.
///
/// Design decisions:
/// - All [StreamSubscription]s are collected in a single [_subscriptions] list
///   and cancelled atomically via [_cancelAllSubscriptions]. This eliminates
///   the "memory leak factory" of a dozen nullable fields each needing manual
///   cancellation.
/// - Channel subscription logic is split into focused private methods to avoid
///   an [initAbly] god-method.
/// - Uses [debugPrint] instead of bare [print] so logs are silenced in release
///   builds automatically.
class AblyService {
  static AblyService get instance => _instance;
  factory AblyService() => _instance;
  AblyService._internal();

  ably.Realtime? _realtime;
  bool _isConnecting = false;
  String? _currentUserId;

  /// All active subscriptions. Cancelled atomically by [_cancelAllSubscriptions].
  final List<StreamSubscription> _subscriptions = [];

  // ── Listener registries ─────────────────────────────────────────────────────

  final List<Function(String orderId, OrderStatus status)> _orderListeners = [];
  final List<Function(String storeId, bool isOpen)> _storeListeners = [];
  final List<Function(String newRole)> _roleListeners = [];
  final List<Function(Map<String, dynamic> payload)> _notificationListeners =
      [];

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initAbly(String userId) async {
    if (_isConnecting) return;

    if (_realtime != null && _currentUserId == userId) {
      _subscribeUserChannel(userId);
      return;
    }

    if (_realtime != null && _currentUserId != userId) {
      disconnect();
    }

    _isConnecting = true;
    _currentUserId = userId;

    try {
      final token = await apiService.storage.read(key: 'launch-fast-token');

      final clientOptions = ably.ClientOptions()
        ..authUrl = '${ApiService.baseUrl}/ably/auth'
        ..authHeaders = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }
        ..clientId = userId;

      _realtime = ably.Realtime(options: clientOptions);

      _subscriptions.add(
        _realtime!.connection.on().listen((ably.ConnectionStateChange change) {
          if (change.current == ably.ConnectionState.connected) {
            _subscribeUserChannel(userId);
            _subscribeStoresChannel();
          }
        }),
      );
    } catch (e) {
      _isConnecting = false;
      _currentUserId = null;
      debugPrint('[AblyService] initAbly failed: $e');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  // ── Private channel helpers ─────────────────────────────────────────────────

  void _subscribeUserChannel(String userId) {
    if (_realtime == null) return;

    final channel = _realtime!.channels.get('user:$userId');

    _subscriptions.add(
      channel.subscribe(name: 'order-update').listen((ably.Message msg) {
        try {
          final data = msg.data as Map;
          final orderId = data['orderId'] as String;
          final status =
              OrderStatusExtension.fromString(data['status'] as String);
          for (final cb in _orderListeners) {
            cb(orderId, status);
          }
        } catch (e) {
          debugPrint('[AblyService] order-update parse error: $e');
        }
      }),
    );

    _subscriptions.add(
      channel.subscribe(name: 'role-update').listen((ably.Message msg) {
        try {
          final newRole = (msg.data as Map)['newRole'] as String;
          for (final cb in _roleListeners) {
            cb(newRole);
          }
        } catch (e) {
          debugPrint('[AblyService] role-update parse error: $e');
        }
      }),
    );

    _subscriptions.add(
      channel
          .subscribe(name: 'general-notification')
          .listen((ably.Message msg) {
        try {
          final data = Map<String, dynamic>.from(msg.data as Map);
          for (final cb in _notificationListeners) {
            cb(data);
          }
        } catch (e) {
          debugPrint('[AblyService] general-notification parse error: $e');
        }
      }),
    );
  }

  void _subscribeStoresChannel() {
    if (_realtime == null) return;

    final channel = _realtime!.channels.get('public:stores');
    _subscriptions.add(
      channel.subscribe(name: 'store-toggle').listen((ably.Message msg) {
        try {
          final data = msg.data as Map;
          final storeId = data['storeId'] as String;
          final isOpen = data['isOpen'] as bool;
          for (final cb in _storeListeners) {
            cb(storeId, isOpen);
          }
        } catch (e) {
          debugPrint('[AblyService] store-toggle parse error: $e');
        }
      }),
    );
  }

  // ── Public subscription API ─────────────────────────────────────────────────

  void subscribeToRiderChannel(
    String riderId, {
    Function(Map data)? onOrderUpdate,
    Function(Map data)? onNewJob,
  }) {
    if (_realtime == null) return;

    final riderChannel = _realtime!.channels.get('rider:$riderId');
    _subscriptions.add(
      riderChannel.subscribe(name: 'order-update').listen((msg) {
        onOrderUpdate?.call(msg.data as Map);
      }),
    );

    final jobsChannel = _realtime!.channels.get('riders:available');
    _subscriptions.add(
      jobsChannel.subscribe(name: 'new-job').listen((msg) {
        onNewJob?.call(msg.data as Map);
      }),
    );
  }

  void subscribeToStoreOrders(String storeId) {
    if (_realtime == null) return;

    final channel = _realtime!.channels.get('store:$storeId:orders');

    _subscriptions.add(
      channel.subscribe(name: 'new-order').listen((msg) {
        try {
          final orderId = (msg.data as Map)['id'] as String;
          for (final cb in _orderListeners) {
            cb(orderId, OrderStatus.pending);
          }
        } catch (_) {}
      }),
    );

    _subscriptions.add(
      channel.subscribe(name: 'order-update').listen((msg) {
        try {
          final data = msg.data as Map;
          final orderId = data['orderId'] as String;
          final status =
              OrderStatusExtension.fromString(data['status'] as String);
          for (final cb in _orderListeners) {
            cb(orderId, status);
          }
        } catch (_) {}
      }),
    );
  }

  void subscribeToUserOrders(
    String userId,
    Function(String orderId, OrderStatus status) onUpdate,
  ) {
    addOrderListener(onUpdate);
    if (_realtime != null) {
      _subscribeUserChannel(userId);
    }
  }

  // ── Listener management ─────────────────────────────────────────────────────

  void addOrderListener(Function(String orderId, OrderStatus status) l) {
    if (!_orderListeners.contains(l)) _orderListeners.add(l);
  }

  void removeOrderListener(Function(String orderId, OrderStatus status) l) =>
      _orderListeners.remove(l);

  void addStoreListener(Function(String storeId, bool isOpen) l) {
    if (!_storeListeners.contains(l)) _storeListeners.add(l);
  }

  void removeStoreListener(Function(String storeId, bool isOpen) l) =>
      _storeListeners.remove(l);

  void addRoleListener(Function(String newRole) l) {
    if (!_roleListeners.contains(l)) _roleListeners.add(l);
  }

  void removeRoleListener(Function(String newRole) l) =>
      _roleListeners.remove(l);

  void addNotificationListener(Function(Map<String, dynamic> payload) l) {
    if (!_notificationListeners.contains(l)) _notificationListeners.add(l);
  }

  void removeNotificationListener(Function(Map<String, dynamic> payload) l) =>
      _notificationListeners.remove(l);

  // ── Teardown ────────────────────────────────────────────────────────────────

  /// Cancels every subscription atomically, then closes the Ably connection.
  void disconnect() {
    _cancelAllSubscriptions();
    _realtime?.close();
    _realtime = null;
    _currentUserId = null;
    _orderListeners.clear();
    _storeListeners.clear();
    _roleListeners.clear();
    _notificationListeners.clear();
    _isConnecting = false;
    debugPrint('[AblyService] Disconnected and listeners cleared.');
  }

  void _cancelAllSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
