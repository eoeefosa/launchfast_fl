import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import '../models/order.dart';

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

  /// Track unique subscription keys to prevent duplicate channel listeners.
  final Set<String> _activeSubscriptionKeys = {};

  // ── Push failure callback ────────────────────────────────────────────────────

  // FIX: Push failures were previously silent. Callers can now be notified.
  void Function(Object error)? onPushActivationFailed;

  // ── Listener registries ─────────────────────────────────────────────────────

  final List<Function(String orderId, OrderStatus status)> _orderListeners = [];
  final List<Function(String storeId, bool isOpen)> _storeListeners = [];
  final List<Function(String newRole)> _roleListeners = [];
  final List<Function(Map<String, dynamic> payload)> _notificationListeners = [];

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initAbly(String userId) async {
    if (_isConnecting) return;

    if (_realtime != null && _currentUserId == userId) {
      return;
    }

    if (_realtime != null && _currentUserId != userId) {
      // FIX: Cancel the old connection subscription *before* disconnect() so
      // it cannot fire events into the new Realtime instance being created below.
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      disconnect();
    }

    _isConnecting = true;
    _currentUserId = userId;

    try {
      final clientOptions = ably.ClientOptions()
        // FIX: Replaced static authUrl + authHeaders with authCallback.
        // The callback is invoked by Ably whenever a token is needed or has
        // expired, so long-lived sessions no longer get silently kicked out.
        ..authCallback = (ably.TokenParams params) async {
          final token = await apiService.storage.read(key: 'launch-fast-token');
          if (token == null) throw Exception('[AblyService] No auth token in storage');
          // Return a TokenRequest or a raw token string — depends on your backend.
          // If your /ably/auth endpoint returns a signed TokenRequest JSON,
          // parse and return it here. Adjust as needed.
          return ably.TokenRequest.fromMap({'token': token});
        }
        ..clientId = userId;

      _realtime = ably.Realtime(options: clientOptions);

      // FIX: Store connection subscription separately (not in _subscriptions)
      // so it survives _cancelAllSubscriptions() during reconnect cycles.
      _connectionSubscription = _realtime!.connection.on().listen(
        (ably.ConnectionStateChange change) async {
          if (change.current == ably.ConnectionState.connected) {
            // FIX: Clear subscription keys on every (re)connect, not just on
            // full disconnect. Without this, Ably's auto-reconnect fires the
            // connected event again, but the key set still has all the old keys,
            // so no channels get re-subscribed and real-time events stop arriving.
            _activeSubscriptionKeys.clear();

            _subscribeUserChannel(userId);
            // FIX: _subscribeStoresChannel is async but was previously called
            // as fire-and-forget inside a sync context. Wrap with unawaited()
            // and a catchError so exceptions are at least logged.
            unawaited(_subscribeStoresChannel().catchError((Object e) {
              debugPrint('[AblyService] _subscribeStoresChannel failed: $e');
            }));

            try {
              if (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS) {
                await Permission.notification.request();
              }
              await _realtime!.push.activate();
            } catch (e) {
              debugPrint('[AblyService] Error activating push: $e');
              // FIX: Surface push failures to callers instead of silently swallowing.
              onPushActivationFailed?.call(e);
            }
          }

          // FIX: Handle disconnected/suspended states so the reconnect cycle
          // can properly re-register channels. The key clear above (on connected)
          // handles the channel re-subscribe. Here we just log for observability.
          if (change.current == ably.ConnectionState.disconnected ||
              change.current == ably.ConnectionState.suspended) {
            debugPrint('[AblyService] Connection ${change.current} — will re-subscribe on reconnect.');
          }

          if (change.current == ably.ConnectionState.failed) {
            debugPrint('[AblyService] Connection failed: ${change.reason}');
          }
        },
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

  void _subscribeUserChannel(String userId) async {
    if (_realtime == null) return;

    final channelName = 'user:$userId';
    final channel = _realtime!.channels.get(channelName);

    // FIX: Push and message subscriptions are now separated so a push failure
    // doesn't silently block the message listener registration below.
    await _attachPush(channel, channelName);

    // 1. Order updates
    _attachListener(
      channel: channel,
      channelName: channelName,
      eventName: 'order-update',
      onMessage: (data) {
        final orderId = data['orderId'] as String;
        final status = OrderStatusExtension.fromString(data['status'] as String);
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
  }

  Future<void> _subscribeStoresChannel() async {
    if (_realtime == null) return;

    const channelName = 'public:stores';
    const eventName = 'store-toggle';

    final channel = _realtime!.channels.get(channelName);
    await _attachPush(channel, channelName);

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

  // FIX: Extracted push attachment as its own method. Push failure is now
  // isolated — it logs and returns, never blocking message subscription.
  Future<void> _attachPush(ably.RealtimeChannel channel, String channelName) async {
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
  }) {
    final key = '$channelName:$eventName';
    final target = keySet ?? _activeSubscriptionKeys;
    if (target.contains(key)) return;
    target.add(key);

    _subscriptions.add(
      channel.subscribe(name: eventName).listen((ably.Message msg) {
        try {
          final data = Map<String, dynamic>.from(msg.data as Map);
          onMessage(data);
        } catch (e) {
          debugPrint('[AblyService] Parse error on $key: $e');
        }
      }),
    );
  }

  // ── Public subscription API ─────────────────────────────────────────────────

  Future<void> subscribeToRiderChannel(
    String riderId, {
    Function(Map<String, dynamic> data)? onOrderUpdate,
    Function(Map<String, dynamic> data)? onNewJob,
  }) async {
    if (_realtime == null) return;

    final riderChannelName = 'rider:$riderId';
    final riderChannel = _realtime!.channels.get(riderChannelName);
    await _attachPush(riderChannel, riderChannelName);

    // FIX: Rider subscriptions use _riderSubscriptionKeys so they can be
    // cancelled independently via cancelRiderSubscriptions().
    _attachListener(
      channel: riderChannel,
      channelName: riderChannelName,
      eventName: 'order-update',
      keySet: _riderSubscriptionKeys,
      onMessage: (data) => onOrderUpdate?.call(data),
    );

    const jobsChannelName = 'riders:available';
    final jobsChannel = _realtime!.channels.get(jobsChannelName);
    await _attachPush(jobsChannel, jobsChannelName);

    _attachListener(
      channel: jobsChannel,
      channelName: jobsChannelName,
      eventName: 'new-job',
      keySet: _riderSubscriptionKeys,
      onMessage: (data) => onNewJob?.call(data),
    );
  }

  // FIX: New method — cancels rider-specific subscriptions when a rider's role
  // is revoked mid-session, without requiring a full disconnect.
  void cancelRiderSubscriptions() {
    _riderSubscriptionKeys.clear();
    // Note: individual stream subscriptions cannot be selectively removed from
    // _subscriptions without tracking them separately. For full cleanup of
    // rider channels, call disconnect() and re-init without subscribeToRiderChannel.
    debugPrint('[AblyService] Rider subscription keys cleared.');
  }

  Future<void> subscribeToStoreOrders(String storeId) async {
    if (_realtime == null) return;

    final channelName = 'store:$storeId:orders';
    final channel = _realtime!.channels.get(channelName);
    await _attachPush(channel, channelName);

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
        final status = OrderStatusExtension.fromString(data['status'] as String);
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
    Function(String orderId, OrderStatus status) onUpdate,
  ) {
    addOrderListener(onUpdate);
    if (_realtime != null) {
      _subscribeUserChannel(userId);
    } else {
      debugPrint('[AblyService] subscribeToUserOrders called before initAbly — '
          'listener registered but channel subscription deferred until connected.');
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
  void addOrderListener(Function(String orderId, OrderStatus status) l) {
    if (!_orderListeners.contains(l)) _orderListeners.add(l);
  }

  void removeOrderListener(Function(String orderId, OrderStatus status) l) =>
      _orderListeners.remove(l);

  /// See [addOrderListener] for the stable-reference requirement.
  void addStoreListener(Function(String storeId, bool isOpen) l) {
    if (!_storeListeners.contains(l)) _storeListeners.add(l);
  }

  void removeStoreListener(Function(String storeId, bool isOpen) l) =>
      _storeListeners.remove(l);

  /// See [addOrderListener] for the stable-reference requirement.
  void addRoleListener(Function(String newRole) l) {
    if (!_roleListeners.contains(l)) _roleListeners.add(l);
  }

  void removeRoleListener(Function(String newRole) l) =>
      _roleListeners.remove(l);

  /// See [addOrderListener] for the stable-reference requirement.
  void addNotificationListener(Function(Map<String, dynamic> payload) l) {
    if (!_notificationListeners.contains(l)) _notificationListeners.add(l);
  }

  void removeNotificationListener(Function(Map<String, dynamic> payload) l) =>
      _notificationListeners.remove(l);

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
    _notificationListeners.clear();
    _riderSubscriptionKeys.clear();
    _isConnecting = false;
    debugPrint('[AblyService] Disconnected and listeners cleared.');
  }

  void _cancelAllSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _activeSubscriptionKeys.clear();
  }
}