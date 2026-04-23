import 'dart:async';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'api_service.dart';
import '../models/order.dart';

class AblyService {
  static final AblyService _instance = AblyService._internal();
  factory AblyService() => _instance;
  AblyService._internal();

  ably.Realtime? _realtime;
  ably.RealtimeChannel? _userChannel;
  ably.RealtimeChannel? _storesChannel;
  ably.RealtimeChannel? _riderChannel;
  ably.RealtimeChannel? _jobsChannel;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _channelSubscription;
  StreamSubscription? _riderSubscription;
  StreamSubscription? _jobsSubscription;
  StreamSubscription? _storesSubscription;
  bool _isConnecting = false;

  // Listener registry for order updates
  final List<Function(String orderId, OrderStatus status)> _orderListeners = [];

  // Listener registry for store updates
  final List<Function(String storeId, bool isOpen)> _storeListeners = [];

  // Listener registry for role updates
  final List<Function(String newRole)> _roleListeners = [];

  // Listener registry for generic notifications
  final List<Function(Map<String, dynamic> payload)> _notificationListeners = [];

  Future<void> initAbly(String userId) async {
    // Prevent duplicate concurrent init calls
    if (_isConnecting) return;

    // If already connected, just ensure channel subscription is active
    if (_realtime != null) {
      _subscribeChannel(userId);
      return;
    }

    _isConnecting = true;

    try {
      final clientOptions = ably.ClientOptions()
        ..autoConnect = true
        ..authCallback = (ably.TokenParams params) async {
          try {
            final response = await apiService.dio.get('/ably/auth');
            return ably.TokenRequest.fromMap(
              response.data as Map<String, dynamic>,
            );
          } catch (e) {
            // print('Ably Auth Error: $e');
            throw Exception('Failed to get Ably token');
          }
        }
        ..clientId = userId;

      _realtime = ably.Realtime(options: clientOptions);

      // Subscribe to channel only once connection is established
      _connectionSubscription = _realtime!.connection.on().listen((
        ably.ConnectionStateChange stateChange,
      ) {
        // print('Ably connection state: ${stateChange.current}');
        if (stateChange.current == ably.ConnectionState.connected) {
          _subscribeChannel(userId);
        }
      });
    } finally {
      _isConnecting = false;
    }
  }

  void _subscribeChannel(String userId) {
    if (_realtime == null) return;

    // Cancel any existing subscription before re-subscribing
    _channelSubscription?.cancel();
    _channelSubscription = null;

    _userChannel = _realtime!.channels.get('user:$userId');
    _channelSubscription = _userChannel!.subscribe(name: 'order-update').listen(
      (ably.Message message) {
        try {
          final data = message.data as Map;
          final orderId = data['orderId'] as String;
          final statusStr = data['status'] as String;
          final status = OrderStatusExtension.fromString(statusStr);
          for (final cb in _orderListeners) {
            cb(orderId, status);
          }
        } catch (e) {
          // print('Error processing order update message: $e');
        }
      },
    );

    // Subscribe to role-update events on the user's personal channel
    _userChannel!.subscribe(name: 'role-update').listen((ably.Message message) {
      try {
        final data = message.data as Map;
        final newRole = data['newRole'] as String;
        for (final cb in _roleListeners) {
          cb(newRole);
        }
      } catch (e) {
        // print("Error processing role update message: $e");
      }
    });

    // Subscribe to general-notification events on the user's personal channel
    _userChannel!.subscribe(name: 'general-notification').listen((ably.Message message) {
      try {
        final data = Map<String, dynamic>.from(message.data as Map);
        for (final cb in _notificationListeners) {
          cb(data);
        }
      } catch (e) {
        // print("Error processing generic notification message: $e");
      }
    });

    // Subscribe to public stores channel
    _storesSubscription?.cancel();
    _storesChannel = _realtime!.channels.get('public:stores');
    _storesSubscription = _storesChannel!
        .subscribe(name: 'store-toggle')
        .listen((ably.Message message) {
          try {
            final data = message.data as Map;
            final storeId = data['storeId'] as String;
            final isOpen = data['isOpen'] as bool;

            // Notify store listeners
            for (final cb in _storeListeners) {
              cb(storeId, isOpen);
            }
          } catch (e) {
            // print('Error processing store toggle message: $e');
          }
        });

    // Subscribe to rider channel if role is rider
    // This is handled via explicit calls to subscribeToRiderChannel
  }

  void subscribeToRiderChannel(
    String riderId, {
    Function(Map data)? onOrderUpdate,
    Function(Map data)? onNewJob,
  }) {
    if (_realtime == null) return;

    // 1. Specific Rider Updates (e.g. status changes of assigned orders)
    _riderSubscription?.cancel();
    _riderChannel = _realtime!.channels.get('rider:$riderId');
    _riderSubscription = _riderChannel!.subscribe(name: 'order-update').listen((
      message,
    ) {
      if (onOrderUpdate != null) {
        onOrderUpdate(message.data as Map);
      }
    });

    // 2. Global Available Jobs
    _jobsSubscription?.cancel();
    _jobsChannel = _realtime!.channels.get('riders:available');
    _jobsSubscription = _jobsChannel!.subscribe(name: 'new-job').listen((
      message,
    ) {
      if (onNewJob != null) {
        onNewJob(message.data as Map);
      }
    });
  }

  void subscribeToStoreOrders(String storeId) {
    if (_realtime == null) return;

    final channelName = 'store:$storeId:orders';
    final channel = _realtime!.channels.get(channelName);

    // Listen for new orders
    channel.subscribe(name: 'new-order').listen((message) {
      try {
        final data = message.data as Map;
        final orderId = data['id'] as String;
        // Notify order listeners
        for (final cb in _orderListeners) {
          cb(orderId, OrderStatus.pending);
        }
      } catch (_) {}
    });

    // Listen for status updates
    channel.subscribe(name: 'order-update').listen((message) {
      try {
        final data = message.data as Map;
        final orderId = data['orderId'] as String;
        final statusStr = data['status'] as String;
        final status = OrderStatusExtension.fromString(statusStr);

        // Notify order listeners
        for (final cb in _orderListeners) {
          cb(orderId, status);
        }
      } catch (_) {}
    });
  }

  // Order listeners
  void addOrderListener(Function(String orderId, OrderStatus status) listener) {
    if (!_orderListeners.contains(listener)) {
      _orderListeners.add(listener);
    }
  }

  void removeOrderListener(
    Function(String orderId, OrderStatus status) listener,
  ) {
    _orderListeners.remove(listener);
  }

  // Store listeners
  void addStoreListener(Function(String storeId, bool isOpen) listener) {
    if (!_storeListeners.contains(listener)) {
      _storeListeners.add(listener);
    }
  }

  void removeStoreListener(Function(String storeId, bool isOpen) listener) {
    _storeListeners.remove(listener);
  }

  // Role listeners — called instantly when admin changes this user's role
  void addRoleListener(Function(String newRole) listener) {
    if (!_roleListeners.contains(listener)) {
      _roleListeners.add(listener);
    }
  }

  void removeRoleListener(Function(String newRole) listener) {
    _roleListeners.remove(listener);
  }

  // Notification listeners
  void addNotificationListener(Function(Map<String, dynamic> payload) listener) {
    if (!_notificationListeners.contains(listener)) {
      _notificationListeners.add(listener);
    }
  }

  void removeNotificationListener(Function(Map<String, dynamic> payload) listener) {
    _notificationListeners.remove(listener);
  }

  void subscribeToUserOrders(
    String userId,
    Function(String orderId, OrderStatus status) onUpdate,
  ) {
    addOrderListener(onUpdate);
    // If already connected, subscribe immediately
    if (_realtime != null) {
      _subscribeChannel(userId);
    }
    // Otherwise, initAbly will call _subscribeChannel once connected
  }

  void disconnect() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _riderSubscription?.cancel();
    _riderSubscription = null;
    _jobsSubscription?.cancel();
    _jobsSubscription = null;
    _storesSubscription?.cancel();
    _storesSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _userChannel = null;
    _riderChannel = null;
    _jobsChannel = null;
    _storesChannel = null;
    _realtime?.close();
    _realtime = null;
    _orderListeners.clear();
    _storeListeners.clear();
    _roleListeners.clear();
    _isConnecting = false;
    // print('Ably disconnected and listeners cleared');
  }
}

final ablyService = AblyService();
