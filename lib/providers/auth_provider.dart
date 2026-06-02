import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../locator.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/location_repository.dart';
import '../services/ably_service.dart';
import '../services/api_service.dart';
import '../services/network_service.dart';
import '../store/pages/core/services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pending social sign-in event — emitted on the [AuthProvider.authEvents]
// stream so the UI layer can react without storing a [BuildContext] in state.
// ─────────────────────────────────────────────────────────────────────────────
enum _SocialProvider { google, apple }

/// Signals emitted by [AuthProvider] that require a UI response.
sealed class AuthEvent {}

/// The user was offline when they attempted a social sign-in.  The UI should
/// show a snackbar / prompt that lets the user retry.
class SocialSignInRetryEvent extends AuthEvent {
  SocialSignInRetryEvent(this.provider);
  final _SocialProvider provider;
}

/// A queued login/register succeeded after connectivity was restored.
class QueuedAuthSuccessEvent extends AuthEvent {}

// ─────────────────────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    FlutterSecureStorage? storage,
    GoogleSignIn? googleSignIn,
    ApiService? apiService,
    AblyService? ablyService,
    AuthRepository? authRepository,
    LocationRepository? locationRepository,
    NetworkService? networkService,
    NotificationService? notificationSvc,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _apiService = apiService ?? locator<ApiService>(),
        _ablyService = ablyService ?? locator<AblyService>(),
        _authRepository = authRepository ?? locator<AuthRepository>(),
        _locationRepository = locationRepository ?? locator<LocationRepository>(),
        _networkService = networkService ?? NetworkService(),
        _notificationService = notificationSvc ?? notificationService,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: const String.fromEnvironment(
                'SERVER_CLIENT_ID',
                defaultValue:
                    '471745302305-tts3kroutn6jofuvcldfckjk4j7et6l2.apps.googleusercontent.com',
              ),
            ) {
    _apiService.onUnauthorized = _handleUnauthorized;
  }

  // ─────────────────────────────────────────────────────────────
  // Storage key constants
  // ─────────────────────────────────────────────────────────────

  static const _kToken           = 'launch-fast-token';
  static const _kUser            = 'launch-fast-user';
  static const _kAdmin           = 'launch-fast-admin';
  static const _kGuestAddress    = 'launch-fast-guest-address';
  static const _kGuestName       = 'launch-fast-guest-name';
  static const _kGuestPhone      = 'launch-fast-guest-phone';
  static const _kSelectedAddress = 'launch-fast-selected-address';
  static const _kQueuedAuthKey   = 'launch-fast-queued-auth';

  // ─────────────────────────────────────────────────────────────
  // Dependencies — all injected, none resolved lazily from globals
  // ─────────────────────────────────────────────────────────────

  final FlutterSecureStorage  _storage;
  final GoogleSignIn           _googleSignIn;
  final ApiService             _apiService;
  final AblyService            _ablyService;
  final AuthRepository         _authRepository;
  final LocationRepository     _locationRepository;
  final NetworkService         _networkService;
  final NotificationService    _notificationService;

  // ─────────────────────────────────────────────────────────────
  // UI event stream
  // Consumers: listen inside initState / didChangeDependencies with a
  // StreamSubscription and cancel it in dispose().  Never store a
  // BuildContext here — emit an event and let the widget react.
  // ─────────────────────────────────────────────────────────────

  final StreamController<AuthEvent> _eventController =
      StreamController<AuthEvent>.broadcast();

  /// Listen to this stream in the widget tree (never store [BuildContext] in
  /// a provider).  Cancel the subscription in [State.dispose].
  Stream<AuthEvent> get authEvents => _eventController.stream;

  // ─────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────

  UserProfile? _user;

  /// Backend JWT **only**.
  /// NEVER assign an FCM / Firebase Messaging token here.
  String? _token;

  bool _isLoading               = false;
  bool _initialized             = false;
  bool _disposed                = false;
  bool _authOperationInProgress = false;

  String? _adminStoreId;
  String? _guestAddress;
  String? _guestName;
  String? _guestPhone;
  String? _selectedAddress;

  List<String> _locations = [];

  bool _ablyListenersAttached        = false;
  bool _tokenRefreshListenerAttached = false;

  // ─────────────────────────────────────────────────────────────
  // Offline-queue state
  // NOTE: BuildContext is intentionally NOT stored.  For login/register,
  // credentials are enough to retry silently.  For social sign-ins, an
  // [AuthEvent] is emitted so the UI can prompt a manual retry.
  // ─────────────────────────────────────────────────────────────

  StreamSubscription<bool>?   _connectivitySubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool                    _isWaitingForConnectivity = false;
  String?                 _queuedAuthType;
  Map<String, dynamic>    _queuedParams             = {};

  bool get isWaitingForConnectivity => _isWaitingForConnectivity;

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────

  UserProfile? get user            => _user;
  String?      get token           => _token;
  bool         get isLoading       => _isLoading;
  bool         get initialized     => _initialized;
  bool         get isAuthenticated => _token != null && _user != null;
  bool         get isAdmin         => _user?.role.toUpperCase() == 'ADMIN';
  bool         get isStoreOwner    => _user?.role.toUpperCase() == 'STORE_OWNER';
  bool         get isWorker        => _user?.role.toUpperCase() == 'STORE_WORKER';
  bool         get isRider         => _user?.role.toUpperCase() == 'RIDER';
  bool         get isStoreApproved => _user?.isStoreApproved ?? false;
  List<String> get locations       => _locations;
  String?      get adminStoreId    => _adminStoreId;
  String?      get currentAddress  => _selectedAddress ?? _guestAddress;
  String?      get selectedAddress => _selectedAddress;
  String?      get guestAddress    => _guestAddress;
  String?      get guestName       => _guestName;
  String?      get guestPhone      => _guestPhone;

  // ─────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _setLoading(true);

    try {
      await _restoreSession();

      // Non-blocking background work — failures are non-fatal.
      unawaited(
        fetchLocation().catchError((Object e) {
          if (kDebugMode) {
            debugPrint('[AuthProvider] Initial fetchLocation failed (non-fatal): $e');
          }
        }),
      );

      if (isAuthenticated) {
        unawaited(
          _initializeAbly().catchError((Object e) {
            if (kDebugMode) {
              debugPrint('[AuthProvider] Initial Ably init failed (non-fatal): $e');
            }
          }),
        );
        _setupTokenRefreshListener();
        _syncFCMTokenSafely();
      }

      await _restoreQueuedAuth();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[AuthProvider] initialize error: $e\n$stack');
      }
    } finally {
      _initialized = true;
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Queued-auth persistence
  // ─────────────────────────────────────────────────────────────

  Future<void> _persistQueuedAuth() async {
    try {
      await _storage.write(
        key:   _kQueuedAuthKey,
        value: jsonEncode(_queuedParams),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] persistQueuedAuth error: $e');
    }
  }

  Future<void> _clearPersistedQueuedAuth() async {
    try {
      await _storage.delete(key: _kQueuedAuthKey);
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] clearPersistedQueuedAuth error: $e');
    }
  }

  Future<void> _restoreQueuedAuth() async {
    try {
      final s = await _storage.read(key: _kQueuedAuthKey);
      if (s == null || s.isEmpty) return;

      final params = jsonDecode(s) as Map<String, dynamic>;
      _queuedParams             = Map<String, dynamic>.from(params);
      _queuedAuthType           = _queuedParams['type'] as String?;
      _isWaitingForConnectivity = true;

      if (kDebugMode) debugPrint('[AuthProvider] restored queued auth: $_queuedAuthType');
      _setupConnectivityListener();
      _safeNotify();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] restoreQueuedAuth error: $e');
    }
  }

  /// Cancels any pending queued auth intent.
  void cancelQueuedAuth() {
    _queuedAuthType           = null;
    _queuedParams             = {};
    _isWaitingForConnectivity = false;
    unawaited(_clearPersistedQueuedAuth());
    _safeNotify();
    if (kDebugMode) debugPrint('[AuthProvider] Queued auth cancelled by user');
  }

  // ─────────────────────────────────────────────────────────────
  // Session Restore
  // ─────────────────────────────────────────────────────────────

  Future<void> _restoreSession() async {
    try {
      final values = await _storage.readAll();

      final token    = values[_kToken];
      final userJson = values[_kUser];

      if (token == null || userJson == null) {
        await _clearSession();
        return;
      }

      if (_isTokenExpired(token)) {
        if (kDebugMode) debugPrint('[AuthProvider] Stored JWT expired — clearing session');
        await _clearSession();
        return;
      }

      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      _assertRequiredUserFields(decoded);

      _token           = token;
      _user            = UserProfile.fromJson(decoded);
      _adminStoreId    = values[_kAdmin];
      _guestAddress    = values[_kGuestAddress];
      _guestName       = values[_kGuestName];
      _guestPhone      = values[_kGuestPhone];
      _selectedAddress = values[_kSelectedAddress];

      if (kDebugMode) {
        debugPrint(
          '[AuthProvider] Session restored — '
          'User ID: ${_user?.id}, Role: ${_user?.role}',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] restore failed: $e');
      await _clearSession();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Token expiry validation
  // ─────────────────────────────────────────────────────────────

  /// Returns true if [token] is expired or malformed.
  /// Uses a 60-second buffer to avoid mid-request expiry.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64Url → base64 with padding
      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);

      final json = jsonDecode(utf8.decode(base64Url.decode(payload)))
          as Map<String, dynamic>;
      final exp = json['exp'];

      if (exp == null) return false; // No exp claim — treat as non-expiring

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        (exp as int) * 1000,
        isUtc: true,
      );

      return DateTime.now().toUtc().isAfter(
            expiry.subtract(const Duration(seconds: 60)),
          );
    } catch (_) {
      return true; // Malformed token — reject
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Required field validation
  // ─────────────────────────────────────────────────────────────

  void _assertRequiredUserFields(Map<String, dynamic> data) {
    if (data['id'] == null && data['_id'] == null) {
      throw const FormatException('Auth response missing required field: id');
    }
    for (final field in const ['name', 'email', 'role']) {
      if (data[field] == null) {
        throw FormatException('Auth response missing required field: $field');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Error helper
  // ─────────────────────────────────────────────────────────────

  String _translateAuthError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'user-not-found'      => 'No user found for that email.',
        'wrong-password'      => 'Wrong password provided.',
        'email-already-in-use'=> 'An account already exists for that email.',
        'invalid-credential'  => 'Invalid email or password.',
        'network-request-failed' => 'Network error. Please check your connection.',
        _ => error.message ?? error.toString(),
      };
    }
    return error.toString()
        .replaceAll('Exception: ', '')
        .replaceAll('Exception', '');
  }

  // ─────────────────────────────────────────────────────────────
  // Login
  // ─────────────────────────────────────────────────────────────

  /// Returns true on success so callers can navigate away.
  Future<bool> login(String email, String password) async {
    if (_authOperationInProgress) return false;

    final online = await _networkService.checkNow();
    if (!online) {
      _queueAuthOperation('login', {'email': email, 'password': password});
      return false;
    }

    return _runAuthOp(() async {
      final data = await _authRepository.login(email, password);
      await _persistAuthResponse(data);
      _initializeAblySafely();
      _syncFCMTokenSafely();
      return true;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Register
  // ─────────────────────────────────────────────────────────────

  /// Returns true on success.
  Future<bool> register(Map<String, dynamic> payload) async {
    if (_authOperationInProgress) return false;

    final online = await _networkService.checkNow();
    if (!online) {
      _queueAuthOperation('register', payload);
      return false;
    }

    return _runAuthOp(() async {
      final data = await _authRepository.register(payload);
      await _persistAuthResponse(data);
      _initializeAblySafely();
      _syncFCMTokenSafely();
      return true;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Offline-queue management
  // ─────────────────────────────────────────────────────────────

  /// Queue [authType] with [params] and start monitoring connectivity.
  void _queueAuthOperation(String authType, Map<String, dynamic> params) {
    _queuedAuthType           = authType;
    _queuedParams             = {
      ...params,
      'type':         authType,
      '_retryCount':  0,
      '_maxRetries':  3,
    };
    _isWaitingForConnectivity = true;

    _setupConnectivityListener();
    unawaited(_persistQueuedAuth());
    _safeNotify();

    if (kDebugMode) debugPrint('[AuthProvider] Queued auth operation: $authType');
  }

  void _setupConnectivityListener() {
    _connectivitySubscription ??=
        _networkService.onConnectivityChanged.listen((isOnline) {
      if (kDebugMode) {
        debugPrint(
          '[AuthProvider] Connectivity: ${isOnline ? 'ONLINE' : 'OFFLINE'}',
        );
      }
      if (isOnline && _isWaitingForConnectivity && _queuedAuthType != null) {
        unawaited(_processQueuedAuthOperation());
      }
    });
  }

  Future<void> _processQueuedAuthOperation() async {
    final authType = _queuedAuthType;
    final params   = Map<String, dynamic>.from(_queuedParams);

    // Clear immediately to prevent double-processing.
    _isWaitingForConnectivity = false;
    _queuedAuthType           = null;
    _queuedParams             = {};
    unawaited(_clearPersistedQueuedAuth());
    _safeNotify();

    if (authType == null) return;

    if (kDebugMode) debugPrint('[AuthProvider] Retrying queued $authType operation');

    try {
      switch (authType) {
        case 'login':
          final email    = params['email']    as String?;
          final password = params['password'] as String?;
          if (email != null && password != null) {
            await login(email, password);
            _eventController.add(QueuedAuthSuccessEvent());
          }

        case 'register':
          // Strip internal retry metadata before forwarding to repository.
          final payload = Map<String, dynamic>.from(params)
            ..remove('type')
            ..remove('_retryCount')
            ..remove('_maxRetries');
          await register(payload);
          _eventController.add(QueuedAuthSuccessEvent());

        // Social sign-ins require live user interaction and cannot be
        // completed silently in the background.  Emit an event so the UI
        // can present a "Tap to retry" prompt without a stored BuildContext.
        case 'google':
          _eventController.add(SocialSignInRetryEvent(_SocialProvider.google));

        case 'apple':
          _eventController.add(SocialSignInRetryEvent(_SocialProvider.apple));

        default:
          if (kDebugMode) {
            debugPrint('[AuthProvider] Unknown queued auth type: $authType');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthProvider] Error processing queued auth ($authType): $e');
      }
      _scheduleRetry(authType, params);
    }
  }

  void _scheduleRetry(String authType, Map<String, dynamic> params) {
    final retryCount = (params['_retryCount'] ?? 0) as int;
    final maxRetries = (params['_maxRetries'] ?? 3) as int;

    if (retryCount >= maxRetries) {
      if (kDebugMode) {
        debugPrint('[AuthProvider] Max retries reached for $authType — giving up');
      }
      return;
    }

    final delaySeconds = 1 << retryCount; // Exponential back-off: 1s, 2s, 4s
    _queuedAuthType           = authType;
    _queuedParams             = {...params, '_retryCount': retryCount + 1};
    _isWaitingForConnectivity = true;
    _safeNotify();

    if (kDebugMode) {
      debugPrint(
        '[AuthProvider] Re-queued $authType — retry #${retryCount + 1} in ${delaySeconds}s',
      );
    }

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (_networkService.isOnline && _isWaitingForConnectivity) {
        unawaited(_processQueuedAuthOperation());
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Auth operation runner — DRY wrapper
  // ─────────────────────────────────────────────────────────────

  Future<bool> _runAuthOp(Future<bool> Function() op) async {
    _authOperationInProgress = true;
    _setLoading(true);
    try {
      return await op();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] auth op error: $e');
      rethrow;
    } finally {
      _authOperationInProgress = false;
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FCM Token Sync
  // ─────────────────────────────────────────────────────────────

  void _syncFCMTokenSafely() {
    unawaited(
      syncFCMToken().catchError((Object e) {
        if (kDebugMode) debugPrint('[AuthProvider] FCM sync failed (non-fatal): $e');
      }),
    );
  }

  Future<void> syncFCMToken() async {
    if (!isAuthenticated) return;

    final fcmToken = await _notificationService.getToken();
    if (fcmToken == null) return;

    if (kDebugMode) debugPrint('[AuthProvider] Syncing FCM token with backend');

    await Future.wait([
      _authRepository.updateProfile({'fcmToken': fcmToken}),
      _pushFcmTokenToBackend(fcmToken),
    ]);
  }

  Future<void> _pushFcmTokenToBackend(String fcmToken) async {
    final userId = _user?.id;
    if (userId == null) return;

    try {
      final response = await _apiService.dio.post(
        '/users/save-token',
        data: {'userId': userId, 'fcmToken': fcmToken},
      );
      if (kDebugMode) {
        final ok =
            response.statusCode == 200 && response.data['success'] == true;
        debugPrint('[AuthProvider] FCM token save: ${ok ? 'OK' : 'failed'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] _pushFcmTokenToBackend error: $e');
      // Non-fatal — next app start will retry.
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Persist auth response
  // ─────────────────────────────────────────────────────────────

  Future<void> _persistAuthResponse(Map<String, dynamic> data) async {
    final rawUser = data['user'] ?? data;
    if (rawUser is! Map) {
      throw const FormatException(
        'Invalid auth response: expected a user object',
      );
    }

    final userMap = Map<String, dynamic>.from(rawUser);
    _assertRequiredUserFields(userMap);

    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const FormatException('Invalid auth response: missing token');
    }

    _user  = UserProfile.fromJson(userMap);
    _token = token; // Backend JWT — never an FCM token.

    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kUser,  value: jsonEncode(_user!.toJson())),
    ]);

    if (kDebugMode) {
      debugPrint(
        '[AuthProvider] Auth persisted — '
        'User ID: ${_user!.id}, Role: ${_user!.role}',
      );
    }

    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // FCM token-refresh listener
  // The FCM token rotates independently of the backend JWT.
  // Refreshing the FCM token MUST NOT touch _token (the JWT).
  // ─────────────────────────────────────────────────────────────

  void _setupTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) return;

    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      if (kDebugMode) debugPrint('[AuthProvider] FCM token rotated — re-syncing');
      _syncFCMTokenSafely();
    });

    _tokenRefreshListenerAttached = true;
  }

  // ─────────────────────────────────────────────────────────────
  // Ably
  // ─────────────────────────────────────────────────────────────

  void _initializeAblySafely() {
    unawaited(
      _initializeAbly().catchError((Object e) {
        if (kDebugMode) debugPrint('[AuthProvider] Ably init failed (non-fatal): $e');
      }),
    );
  }

  Future<void> _initializeAbly() async {
    if (_ablyListenersAttached) return;
    final userId = _user?.id;
    if (userId == null) return;

    await _ablyService.initAbly(userId);
    _ablyService.addRoleListener(_handleRoleUpdate);
    _ablyService.addStoreApprovalListener(_handleStoreApproval);
    _ablyService.addWalletListener(refreshUser);

    unawaited(
      _notificationService.subscribeToUserTopic(userId).catchError((Object e) {
        if (kDebugMode) debugPrint('[AuthProvider] FCM topic subscribe failed: $e');
      }),
    );

    _ablyListenersAttached = true;
  }

  // ─────────────────────────────────────────────────────────────
  // Locations
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchLocation() async {
    try {
      _locations = await _locationRepository.getLocations();
      _safeNotify();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] fetchLocation error: $e');
    }
  }

  /// Alias kept for call-site compatibility.
  Future<void> fetchLocations() => fetchLocation();

  Future<void> setDeliveryAddress(String address) async {
    _selectedAddress = address;
    await _storage.write(key: _kSelectedAddress, value: address);
    _safeNotify();
  }

  Future<void> setGuestAddress(String address) async {
    _guestAddress = address;
    await _storage.write(key: _kGuestAddress, value: address);
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Profile
  // ─────────────────────────────────────────────────────────────

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      final data     = await _authRepository.updateProfile(updates);
      final userData = data['user'] ?? data;
      _user = UserProfile.fromJson(Map<String, dynamic>.from(userData));
      await _storage.write(key: _kUser, value: jsonEncode(_user!.toJson()));
      _safeNotify();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] updateProfile error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    try {
      final data     = await _authRepository.getProfile();
      final userData = data['user'] ?? data;
      _user = UserProfile.fromJson(Map<String, dynamic>.from(userData));
      await _storage.write(key: _kUser, value: jsonEncode(_user!.toJson()));
      _safeNotify();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] refreshUser error: $e');
    }
  }

  Future<void> toggleFavorite(String storeId) async {
    if (!isAuthenticated) return;
    try {
      final data = await _authRepository.toggleFavorite(storeId);
      if (data['success'] == true) {
        final favorites = List<String>.from(data['favoriteStores'] as List);
        await updateUser({'favoriteStores': favorites});
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] toggleFavorite error: $e');
      rethrow;
    }
  }

  void updateRole(String role) => _handleRoleUpdate(role);

  Future<void> updateNameAndPhone({String? name, String? phone}) async {
    if (!isAuthenticated || _user == null) return;
    if (name == null && phone == null) return;

    // Build a map with only the fields that were actually provided.
    final updates = <String, dynamic>{
      'name':  ?name,
      'phone': ?phone,
    };

    await updateUser(updates); // Optimistic local update

    try {
      await _authRepository.updateProfile(updates);
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] updateNameAndPhone error: $e');
      // Non-fatal — local state is already updated.
    }
  }

  /// Returns true if the user's wallet balance covers [total].
  bool hasSufficientFunds(double total) =>
      (_user?.walletBalance ?? 0) >= total;

  void setGuestInfo({String? name, String? phone}) {
    if (name  != null) _guestName  = name;
    if (phone != null) _guestPhone = phone;
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Social Sign-In
  // ─────────────────────────────────────────────────────────────

  /// Returns true on success.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final online = await _networkService.checkNow();
      if (!online) {
        _queueAuthOperation('google', {});
        return false;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential  = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) throw Exception('Failed to get Firebase ID token');

      final data = await _authRepository.loginWithGoogle(firebaseIdToken);
      await _persistAuthResponse(data);
      _initializeAblySafely();
      _syncFCMTokenSafely();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] signInWithGoogle error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns true on success.
  Future<bool> signInWithApple() async {
    _setLoading(true);
    try {
      final online = await _networkService.checkNow();
      if (!online) {
        _queueAuthOperation('apple', {});
        return false;
      }

      final rawNonce = _generateNonce();
      final nonce    = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.campuschow.service',
          redirectUri: Uri.parse(
            'https://try-auth-f5762.firebaseapp.com/__/auth/handler',
          ),
        ),
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw Exception('Apple Sign-In failed: No identity token received');
      }

      final credential = OAuthProvider('apple.com').credential(
        idToken:     idToken,
        rawNonce:    rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential  = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) throw Exception('Failed to get Firebase ID token');

      String? fullName;
      final given  = appleCredential.givenName;
      final family = appleCredential.familyName;
      if (given != null || family != null) {
        fullName = '${given ?? ''} ${family ?? ''}'.trim();
        if (fullName.isEmpty) fullName = null;
      }

      final data = await _authRepository.loginWithApple(
        firebaseIdToken,
        name: fullName,
      );
      await _persistAuthResponse(data);
      _initializeAblySafely();
      _syncFCMTokenSafely();
      return true;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[AuthProvider] signInWithApple error: $e\n$stack');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Account deletion
  // ─────────────────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    _setLoading(true);
    try {
      await _reauthenticateIfNeeded(firebaseUser);
      await _authRepository.deleteAccount();
      await logout();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] deleteAccount error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _reauthenticateIfNeeded(User user) async {
    final providers = user.providerData.map((p) => p.providerId).toSet();

    if (providers.contains('apple.com')) {
      final rawNonce = _generateNonce();
      final nonce    = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.campuschow.service',
          redirectUri: Uri.parse(
            'https://try-auth-f5762.firebaseapp.com/__/auth/handler',
          ),
        ),
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw Exception('Apple re-authentication failed: No identity token received');
      }

      await user.reauthenticateWithCredential(
        OAuthProvider('apple.com').credential(
          idToken:     idToken,
          rawNonce:    rawNonce,
          accessToken: appleCredential.authorizationCode,
        ),
      );
    } else if (providers.contains('google.com')) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google re-authentication cancelled');

      final googleAuth = await googleUser.authentication;
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken:     googleAuth.idToken,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Store application
  // ─────────────────────────────────────────────────────────────

  Future<void> applyForStore(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _authRepository.applyForStore(data);
      final userData = response['user'] ?? response;
      _user = UserProfile.fromJson(Map<String, dynamic>.from(userData));
      await _storage.write(key: _kUser, value: jsonEncode(_user!.toJson()));
      _safeNotify();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] applyForStore error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Real-time event handlers
  // ─────────────────────────────────────────────────────────────

  void _handleRoleUpdate(String role) {
    if (_disposed || _user == null || _user!.role == role) return;
    unawaited(updateUser({'role': role}));
  }

  void _handleStoreApproval(String storeId) {
    if (_disposed || _user == null || _user!.isStoreApproved) return;
    unawaited(updateUser({'isStoreApproved': true}));
  }

  // ─────────────────────────────────────────────────────────────
  // 401 handler
  // ─────────────────────────────────────────────────────────────

  Future<void> _handleUnauthorized() async {
    if (kDebugMode) debugPrint('[AuthProvider] 401 received — logging out');
    await logout(disconnectGoogle: false);
  }

  // ─────────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────────

  Future<void> logout({bool disconnectGoogle = true}) async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;

    try {
      final userId = _user?.id;
      if (userId != null) {
        unawaited(
          _notificationService.unsubscribeFromUserTopic(userId).catchError(
            (Object e) {
              if (kDebugMode) debugPrint('[AuthProvider] FCM unsubscribe failed: $e');
            },
          ),
        );
      }

      await _clearSession();
      _ablyService.disconnect();

      // Reset flags so listeners re-attach on next login.
      _ablyListenersAttached        = false;
      _tokenRefreshListenerAttached = false;

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      if (disconnectGoogle) await _googleSignIn.signOut();
    } finally {
      _authOperationInProgress = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Clear session
  // Targeted deletes only — never wipe keys owned by other modules.
  // ─────────────────────────────────────────────────────────────

  Future<void> _clearSession() async {
    _user         = null;
    _token        = null;
    _adminStoreId = null;

    await Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kUser),
      _storage.delete(key: _kAdmin),
      _storage.delete(key: _kGuestAddress),
      _storage.delete(key: _kGuestName),
      _storage.delete(key: _kGuestPhone),
      _storage.delete(key: _kSelectedAddress),
    ]);

    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Update user
  // ─────────────────────────────────────────────────────────────

  Future<void> updateUser(Map<String, dynamic> updates) async {
    if (_user == null) return;

    _user = UserProfile.fromJson({..._user!.toJson(), ...updates});
    await _storage.write(key: _kUser, value: jsonEncode(_user!.toJson()));
    _safeNotify();
  }

  /// Updates wallet balance locally without a full profile re-fetch.
  void updateWalletBalance(double newBalance) {
    if (_user == null) return;
    _user = UserProfile.fromJson({..._user!.toJson(), 'walletBalance': newBalance});
    unawaited(_storage.write(key: _kUser, value: jsonEncode(_user!.toJson())));
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Nonce helpers (Apple Sign-In)
  // ─────────────────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _sha256ofString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  // ─────────────────────────────────────────────────────────────
  // Loading
  // ─────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Safe notify — guards against post-dispose calls
  // ─────────────────────────────────────────────────────────────

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    _apiService.onUnauthorized = null;
    _ablyService.disconnect();
    _connectivitySubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _eventController.close();
    super.dispose();
  }
}
