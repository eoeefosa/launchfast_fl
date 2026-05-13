import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:permission_handler/permission_handler.dart';
import 'package:campuschow/store/lib/core/network/api_client.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';

/// A focused real-time messaging service backed by Ably.
///
/// Design decisions:
/// - All [StreamSubscription]s are collected in a single [_subscriptions] list
///   and cancelled atomically via [_cancelAllSubscriptions].
/// - [_activeSubscriptionKeys] is cleared on every disconnection event (not just
///   full [disconnect]) so that Ably's auto-reconnect cycle can re-register
///   channel subscriptions correctly.
/// - Auth uses [authCallback] instead of static [authHeaders] so that expired
///   tokens are refreshed automatically during long sessions.
/// - Push activation failures surface via [onPushActivationFailed] so callers
///   can react (e.g. show a UI banner or retry).
/// - Rider/store-order subscriptions are tracked in dedicated key sets so they
///   can be cancelled independently without a full [disconnect].
/// - Uses [debugPrint] so logs are silenced in release builds automatically.
class AblyService {
  // FIX: No public constructor — use the singleton accessor below.
  // This prevents two parts of the app from creating separate Ably connections.
  AblyService._();
  static final AblyService instance = AblyService._();

  ably.Realtime? _realtime;
  bool _isConnecting = false;
  String? _currentUserId;

  // FIX: The connection-state subscription is stored separately so it can be
  // cancelled cleanly before replacing _realtime on a userId switch. Previously
  // it lived in _subscriptions and would fire events into the new instance.
  StreamSubscription? _connectionSubscription;

  /// All active channel subscriptions. Cancelled atomically by [_cancelAllSubscriptions].
  final List<StreamSubscription> _subscriptions = [];

  /// Subscription keys for rider-specific channels. Stored separately so
  /// [cancelRiderSubscriptions] can revoke them without a full disconnect.
  final Set<String> _riderSubscriptionKeys = {};
  final List<StreamSubscription> _riderSubscriptions = [];

  /// Track unique subscription keys to prevent duplicate channel listeners.
  final Set<String> _activeSubscriptionKeys = {};

  // ── Push failure callback ────────────────────────────────────────────────────

  // FIX: Push failures were previously silent. Callers can now be notified.
  void Function(Object error)? onPushActivationFailed;

  // ── Listener registries ─────────────────────────────────────────────────────

  final List<void Function(String orderId, OrderStatus status)> _orderListeners = [];
  final List<void Function(String storeId, bool isOpen)> _storeListeners = [];
  final List<void Function(String newRole)> _roleListeners = [];
  final List<void Function(String storeId)> _approvalListeners = [];
  final List<void Function(Map<String, dynamic> payload)> _notificationListeners = [];
  final List<void Function(String storeId, String? menuItemId, bool? isReady)> _menuListeners = [];

  // ── Init ────────────────────────────────────────────────────────────────────
  Future<void> initAbly(String userId) async {
    debugPrint('--- [AblyService] Initializing for user: $userId ---');
    if (_isConnecting) {
      debugPrint('[AblyService] Already connecting, skipping...');
      return;
    }

    if (_realtime != null && _currentUserId == userId) {
      debugPrint('[AblyService] Already connected for this user.');
      return;
    }

    if (_realtime != null && _currentUserId != userId) {
      debugPrint(
        '[AblyService] Switching user, disconnecting old connection...',
      );
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      disconnect();
    }

    _isConnecting = true;
    _currentUserId = userId;

    // Fail fast if we don't even have a session token.
    final token = await apiService.storage.read(key: 'launch-fast-token');
    if (token == null) {
      debugPrint('[AblyService] No token found in storage, aborting initAbly');
      _isConnecting = false;
      _currentUserId = null;
      throw Exception('[AblyService] No auth token in storage');
    }

    ably.Realtime? rt;

    try {
      debugPrint('[AblyService] Creating client options...');
      final clientOptions = ably.ClientOptions()
        ..autoConnect = false
        ..authCallback = (ably.TokenParams params) async {
          debugPrint('[AblyService] authCallback triggered');

          if (_realtime == null && rt == null) {
            throw Exception(
              '[AblyService] authCallback fired after disconnect',
            );
          }

          final token = await apiService.storage.read(key: 'launch-fast-token');
          if (token == null) {
            debugPrint('[AblyService] No token found in storage');
            throw Exception('[AblyService] No auth token in storage');
          }

          try {
            debugPrint('[AblyService] Fetching Ably token from backend...');
            final response = await apiService.dio.get(
              '/ably/auth',
              options: Options(
                sendTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );
            debugPrint(
              '[AblyService] Ably auth raw response: ${response.statusCode} ${response.data}',
            );

            final data = response.data;

            if (data is String) return data;

            if (data is Map<String, dynamic>) {
              if (data.containsKey('keyName')) {
                return ably.TokenRequest.fromMap(data);
              }
              if (data.containsKey('token')) {
                final tokenVal = data['token'];
                if (tokenVal is String) return tokenVal;
                return ably.TokenDetails.fromMap(data);
              }
              return ably.TokenRequest.fromMap(data);
            }
            return data;
          } on DioException catch (e) {
            debugPrint(
              '[AblyService] authCallback Dio error: ${e.type} — ${e.message} — status: ${e.response?.statusCode}',
            );
            rethrow;
          } catch (e) {
            debugPrint('[AblyService] authCallback failed: $e');
            rethrow;
          }
        }
        ..clientId = userId;

      debugPrint('[AblyService] Initializing Realtime instance...');
      rt = ably.Realtime(options: clientOptions);

      _connectionSubscription = rt.connection.on().listen((
        ably.ConnectionStateChange change,
      ) async {
        final current = _realtime;
        if (current == null) return;

        debugPrint(
          '[AblyService] Connection state change: ${change.previous} -> ${change.current}',
        );

        if (change.current == ably.ConnectionState.connected) {
          debugPrint('[AblyService] Connected successfully');
          _activeSubscriptionKeys.clear();

          _subscribeUserChannel(userId);
          unawaited(
            _subscribeStoresChannel().catchError((Object e) {
              debugPrint('[AblyService] _subscribeStoresChannel failed: $e');
            }),
          );
          unawaited(
            _subscribeMenuChannel().catchError((Object e) {
              debugPrint('[AblyService] _subscribeMenuChannel failed: $e');
            }),
          );

          try {
            debugPrint('[AblyService] Requesting notification permissions...');
            if (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) {
              await Permission.notification.request();
            }
            if (_realtime == null) return;
            debugPrint('[AblyService] Activating push...');
            await current.push.activate();
            debugPrint('[AblyService] Push activated');
          } catch (e) {
            debugPrint('[AblyService] Error activating push: $e');
            onPushActivationFailed?.call(e);
          }
        }

        if (change.current == ably.ConnectionState.disconnected ||
            change.current == ably.ConnectionState.suspended) {
          debugPrint(
            '[AblyService] Connection ${change.current} — clearing subscription keys for re-subscribe on reconnect.',
          );
          _activeSubscriptionKeys.clear();
        }

        if (change.current == ably.ConnectionState.failed) {
          debugPrint('[AblyService] Connection failed: ${change.reason}');
        }
      });

      _realtime = rt;

      debugPrint('[AblyService] Connecting...');
      rt.connect();

      // Wait for connected or failed rather than fire-and-forget
      final completer = Completer<void>();
      late StreamSubscription<ably.ConnectionStateChange> waitSub;
      waitSub = rt.connection.on().listen((ably.ConnectionStateChange change) {
        if (change.current == ably.ConnectionState.connected) {
          waitSub.cancel();
          if (!completer.isCompleted) completer.complete();
        } else if (change.current == ably.ConnectionState.failed) {
          waitSub.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('Ably connection failed: ${change.reason}'),
            );
          }
        }
      });

      await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          waitSub.cancel();
          throw TimeoutException(
            '[AblyService] Connection timed out after 20s',
          );
        },
      );

      debugPrint('[AblyService] initAbly complete for $userId');
    } catch (e) {
      debugPrint('[AblyService] initAbly failed: $e');
      if (_realtime == null && rt != null) {
        try {
          rt.close();
        } catch (_) {}
      }
      _isConnecting = false;
      _currentUserId = null;
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  void _subscribeUserChannel(String userId) async {
    // FIX: Snapshot to guard against disconnect() nulling _realtime across the
    // async boundary below (_attachPush is awaited).
    final rt = _realtime;
    if (rt == null) return;

    final channelName = 'user:$userId';
    final channel = rt.channels.get(channelName);

    // FIX: Push and message subscriptions are now separated so a push failure
    // doesn't silently block the message listener registration below.
    await _attachPush(channel, channelName);

    // FIX: Re-check after async gap to avoid attaching listeners if
    // disconnect() was called while awaiting push registration.
    if (_realtime != rt) return;

    // 1. Order updates
    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'order-update',
      onMessage: (data) {
        final orderId = data['orderId'] as String;
        final status = OrderStatusExtension.fromString(
          data['status'] as String,
        );
        for (final cb in _orderListeners) {
          cb(orderId, status);
        }
      },
    );

    // 2. Role updates
    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'role-update',
      onMessage: (data) {
        final newRole = data['newRole'] as String;
        for (final cb in _roleListeners) {
          cb(newRole);
        }
      },
    );

    // 3. General notifications
    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'general-notification',
      onMessage: (data) {
        for (final cb in _notificationListeners) {
          cb(data);
        }
      },
    );

    // 4. Store approval
    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'store-approved',
      onMessage: (data) {
        final storeId = data['storeId'] as String;
        for (final cb in _approvalListeners) {
          cb(storeId);
        }
      },
    );
  }

  Future<void> _subscribeStoresChannel() async {
    // FIX: Snapshot to guard against disconnect() nulling _realtime across the
    // async boundary below (_attachPush is awaited).
    final rt = _realtime;
    if (rt == null) return;

    const channelName = 'public:stores';
    const eventName = 'store-toggle';

    final channel = rt.channels.get(channelName);
    await _attachPush(channel, channelName);

    // FIX: Re-check after async gap.
    if (_realtime != rt) return;

    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: eventName,
      onMessage: (data) {
        final storeId = data['storeId'] as String;
        final isOpen = data['isOpen'] as bool;
        for (final cb in _storeListeners) {
          cb(storeId, isOpen);
        }
      },
    );
  }

  Future<void> _subscribeMenuChannel() async {
    // FIX: Snapshot to guard against disconnect() nulling _realtime across the
    // async boundary below (_attachPush is awaited).
    final rt = _realtime;
    if (rt == null) return;

    const channelName = 'public:menu';
    final channel = rt.channels.get(channelName);
    await _attachPush(channel, channelName);

    // FIX: Re-check after async gap.
    if (_realtime != rt) return;

    // 1. Specific menu item availability update
    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'menu-item-update',
      onMessage: (data) {
        final storeId = data['storeId'] as String;
        final menuItemId = data['menuItemId'] as String;
        final isReady = data['isReady'] as bool;
        for (final cb in _menuListeners) {
          cb(storeId, menuItemId, isReady);
        }
      },
    );

    // 2. Structural menu change
    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'menu-changed',
      onMessage: (data) {
        final storeId = data['storeId'] as String;
        for (final cb in _menuListeners) {
          cb(storeId, null, null);
        }
      },
    );
  }

  // FIX: Extracted push attachment as its own method. Push failure is now
  // isolated — it logs and returns, never blocking message subscription.
  Future<void> _attachPush(
    ably.RealtimeChannel channel,
    String channelName,
  ) async {
    try {
      await channel.push.subscribeClient();
    } catch (e) {
      debugPrint('[AblyService] Push subscribe failed for $channelName: $e');
    }
  }

  // FIX: Extracted the duplicate-guard + listen pattern into a single helper.
  // All channel subscriptions now go through here, eliminating the repeated
  // key-check boilerplate across every subscribe method.
  void _attachListener({
    required ably.RealtimeChannel channel,
    required String channelName,
    required String eventName,
    required void Function(Map<String, dynamic> data) onMessage,
    Set<String>? keySet,
    List<StreamSubscription>? subscriptionList,
  }) {
    final key = '$channelName:$eventName';
    final target = keySet ?? _activeSubscriptionKeys;
    if (target.contains(key)) return;
    target.add(key);

    final sub = channel.subscribe(name: eventName).listen((ably.Message msg) {
      try {
        final data = Map<String, dynamic>.from(msg.data as Map);
        onMessage(data);
      } catch (e) {
        debugPrint('[AblyService] Parse error on $key: $e');
      }
    });

    if (subscriptionList != null) {
      subscriptionList.add(sub);
    } else {
      _subscriptions.add(sub);
    }
  }

  // ── Public subscription API ─────────────────────────────────────────────────

  Future<void> subscribeToRiderChannel(
    String riderId, {
    void Function(Map<String, dynamic> data)? onOrderUpdate,
    void Function(Map<String, dynamic> data)? onNewJob,
  }) async {
    // FIX: Snapshot _realtime so a concurrent disconnect() can't null it
    // between the guard and subsequent accesses (two await gaps in this method).
    final rt = _realtime;
    if (rt == null) return;

    final riderChannelName = 'rider:$riderId';
    final riderChannel = rt.channels.get(riderChannelName);
    await _attachPush(riderChannel, riderChannelName);

    // FIX: Re-check after async gap.
    if (_realtime != rt) return;

    // FIX: Rider subscriptions use _riderSubscriptionKeys so they can be
    // cancelled independently via cancelRiderSubscriptions().
    _attachListener(
      channel: riderChannel,
      channelName: riderChannelName,
      eventName: 'order-update',
      keySet: _riderSubscriptionKeys,
      subscriptionList: _riderSubscriptions,
      onMessage: (data) => onOrderUpdate?.call(data),
    );

    // FIX: Previously used _realtime! here — second force-unwrap after an
    // await, so the same race applied. Now uses the captured rt.
    const jobsChannelName = 'riders:available';
    final jobsChannel = rt.channels.get(jobsChannelName);
    await _attachPush(jobsChannel, jobsChannelName);

    // FIX: Re-check after second async gap in this method.
    if (_realtime != rt) return;

    _attachListener(
      channel: jobsChannel,
      channelName: jobsChannelName,
      eventName: 'new-job',
      keySet: _riderSubscriptionKeys,
      subscriptionList: _riderSubscriptions,
      onMessage: (data) => onNewJob?.call(data),
    );
  }

  // FIX: New method — cancels rider-specific subscriptions when a rider's role
  // is revoked mid-session, without requiring a full disconnect.
  void cancelRiderSubscriptions() {
    _riderSubscriptionKeys.clear();
    for (final sub in _riderSubscriptions) {
      sub.cancel();
    }
    _riderSubscriptions.clear();
    debugPrint('[AblyService] Rider subscriptions cancelled and keys cleared.');
  }

  Future<void> subscribeToStoreOrders(String storeId) async {
    // FIX: Snapshot _realtime so a concurrent disconnect() can't null it
    // between the guard and the force-unwrap after the await _attachPush gap.
    final rt = _realtime;
    if (rt == null) return;

    final channelName = 'store:$storeId:orders';
    final channel = rt.channels.get(channelName);
    await _attachPush(channel, channelName);

    // FIX: Re-check after async gap.
    if (_realtime != rt) return;

    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'new-order',
      onMessage: (data) {
        final orderId = data['id'] as String;
        for (final cb in _orderListeners) {
          cb(orderId, OrderStatus.pending);
        }
      },
    );

    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'order-update',
      onMessage: (data) {
        final orderId = data['orderId'] as String;
        final status = OrderStatusExtension.fromString(
          data['status'] as String,
        );
        for (final cb in _orderListeners) {
          cb(orderId, status);
        }
      },
    );
  }

  // FIX: subscribeToUserOrders now warns if called before initAbly rather than
  // silently registering a listener that will never fire.
  void subscribeToUserOrders(
    String userId,
    void Function(String orderId, OrderStatus status) onUpdate,
  ) {
    addOrderListener(onUpdate);
    if (_realtime != null) {
      _subscribeUserChannel(userId);
    } else {
      debugPrint(
        '[AblyService] subscribeToUserOrders called before initAbly — '
        'listener registered but channel subscription deferred until connected.',
      );
    }
  }

  // ── Listener management ─────────────────────────────────────────────────────
  //
  // FIX: Document the function-reference constraint prominently. Dart's closure
  // equality is identity-based, so callers MUST pass a stable reference (a named
  // method or a stored closure) — not an inline lambda — or duplicates will accumulate.

  /// Adds [l] to the order listener registry.
  ///
  /// IMPORTANT: Pass a stable function reference (a named method or a stored
  /// closure), never an inline lambda. Dart compares closures by identity, so a
  /// new lambda on every call will not be deduplicated and will accumulate.
  void addOrderListener(void Function(String orderId, OrderStatus status) l) {
    if (!_orderListeners.contains(l)) _orderListeners.add(l);
  }

  void removeOrderListener(void Function(String orderId, OrderStatus status) l) =>
      _orderListeners.remove(l);

  /// See [addOrderListener] for the stable-reference requirement.
  void addMenuListener(
    void Function(String storeId, String? menuItemId, bool? isReady) l,
  ) {
    if (!_menuListeners.contains(l)) _menuListeners.add(l);
  }

  void removeMenuListener(
    void Function(String storeId, String? menuItemId, bool? isReady) l,
  ) => _menuListeners.remove(l);

  /// See [addOrderListener] for the stable-reference requirement.
  void addStoreListener(void Function(String storeId, bool isOpen) l) {
    if (!_storeListeners.contains(l)) _storeListeners.add(l);
  }

  void removeStoreListener(void Function(String storeId, bool isOpen) l) =>
      _storeListeners.remove(l);

  /// See [addOrderListener] for the stable-reference requirement.
  void addRoleListener(void Function(String newRole) l) {
    if (!_roleListeners.contains(l)) _roleListeners.add(l);
  }

  void removeRoleListener(void Function(String newRole) l) =>
      _roleListeners.remove(l);

  /// See [addOrderListener] for the stable-reference requirement.
  void addNotificationListener(void Function(Map<String, dynamic> payload) l) {
    if (!_notificationListeners.contains(l)) _notificationListeners.add(l);
  }

  void removeNotificationListener(void Function(Map<String, dynamic> payload) l) =>
      _notificationListeners.remove(l);

  /// See [addOrderListener] for the stable-reference requirement.
  void addStoreApprovalListener(void Function(String storeId) l) {
    if (!_approvalListeners.contains(l)) _approvalListeners.add(l);
  }

  void removeStoreApprovalListener(void Function(String storeId) l) =>
      _approvalListeners.remove(l);

  // ── Teardown ────────────────────────────────────────────────────────────────

  /// Cancels every subscription atomically, then closes the Ably connection.
  void disconnect() {
    // FIX: Cancel the connection subscription first so it cannot fire
    // reconnection events while teardown is in progress.
    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _cancelAllSubscriptions();
    _realtime?.close();
    _realtime = null;
    _currentUserId = null;
    _orderListeners.clear();
    _storeListeners.clear();
    _roleListeners.clear();
    _approvalListeners.clear();
    _notificationListeners.clear();
    // FIX: _menuListeners was previously omitted from teardown — old menu
    // callbacks would survive logout and fire for a subsequent user's session.
    _menuListeners.clear();
    _riderSubscriptionKeys.clear();
    _riderSubscriptions.clear();
    _isConnecting = false;
    debugPrint('[AblyService] Disconnected and listeners cleared.');
  }

  void _cancelAllSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _activeSubscriptionKeys.clear();

    for (final sub in _riderSubscriptions) {
      sub.cancel();
    }
    _riderSubscriptions.clear();
    _riderSubscriptionKeys.clear();
  }
}

final ablyService = AblyService.instance;
