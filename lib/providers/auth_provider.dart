import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:campuschow/utils/ui_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:campuschow/repositories/location_repository.dart';

import '../locator.dart';
import '../services/ably_service.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {

  AuthProvider({
    FlutterSecureStorage? storage,
    GoogleSignIn? googleSignIn,
    // FIX #6 — inject services instead of using globals
    ApiService? apiService,
    AblyService? ablyService,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _apiService = apiService ?? locator<ApiService>(),
        _ablyService = ablyService ?? locator<AblyService>(),
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          serverClientId: const String.fromEnvironment(
            'SERVER_CLIENT_ID',
            defaultValue: '471745302305-tts3kroutn6jofuvcldfckjk4j7et6l2.apps.googleusercontent.com',
          ),
        ) {
    _apiService.onUnauthorized = _handleUnauthorized;
  }

  // ─────────────────────────────────────────────────────────────
  // Storage key constants
  // FIX: centralise keys so a typo is a compile error, not a runtime bug
  // ─────────────────────────────────────────────────────────────

  static const _kToken           = 'launch-fast-token';
  static const _kUser            = 'launch-fast-user';
  static const _kAdmin           = 'launch-fast-admin';
  static const _kGuestAddress    = 'launch-fast-guest-address';
  static const _kGuestName       = 'launch-fast-guest-name';
  static const _kGuestPhone      = 'launch-fast-guest-phone';
  static const _kSelectedAddress = 'launch-fast-selected-address';

  // ─────────────────────────────────────────────────────────────
  // Dependencies
  // ─────────────────────────────────────────────────────────────

  final FlutterSecureStorage _storage;
  final GoogleSignIn         _googleSignIn;
  // FIX #6 — injected, not global
  final ApiService  _apiService;
  final AblyService _ablyService;

  // ─────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────

  UserProfile? _user;

  /// Backend JWT only.
  /// NEVER assign an FCM / Firebase Messaging token to this field — they are
  /// completely different tokens used for different purposes.
  String? _token;

  bool _isLoading             = false;
  bool _initialized           = false;
  bool _disposed              = false;
  bool _authOperationInProgress = false;

  String? _adminStoreId;
  String? _guestAddress;
  String? _guestName;
  String? _guestPhone;
  String? _selectedAddress;

  List<String> _locations = [];

  bool _ablyListenersAttached      = false;
  bool _tokenRefreshListenerAttached = false;

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
      // Restore user session offline instantly (takes <10ms)
      await _restoreSession();

      // Trigger location fetching in the background without blocking the boot sequence
      fetchLocation().catchError((e) {
        if (kDebugMode) {
          debugPrint('[AuthProvider] Initial fetchLocation failed (non-fatal): $e');
        }
      });

      if (isAuthenticated) {
        // Initialize Ably real-time services asynchronously in the background
        _initializeAbly().catchError((e) {
          if (kDebugMode) {
            debugPrint('[AuthProvider] Initial Ably initialization failed (non-fatal): $e');
          }
        });
        _setupTokenRefreshListener();
        _syncFCMTokenSafely();
      }
    } catch (e, stack) {
      // FIX #3 — sensitive details behind kDebugMode guard
      if (kDebugMode) {
        debugPrint('[AuthProvider] initialize error: $e');
        debugPrint(stack.toString());
      }
    } finally {
      _initialized = true;
      _setLoading(false);
    }
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

      // FIX #4 — validate token expiry before trusting stored credentials
      if (_isTokenExpired(token)) {
        if (kDebugMode) {
          debugPrint('[AuthProvider] Stored JWT is expired — clearing session');
        }
        await _clearSession();
        return;
      }

      final decoded = jsonDecode(userJson) as Map<String, dynamic>;

      // FIX #12 — validate required fields before constructing the model
      _assertRequiredUserFields(decoded);

      final restoredUser = UserProfile.fromJson(decoded);

      _token           = token;
      _user            = restoredUser;
      _adminStoreId    = values[_kAdmin];
      _guestAddress    = values[_kGuestAddress];
      _guestName       = values[_kGuestName];
      _guestPhone      = values[_kGuestPhone];
      _selectedAddress = values[_kSelectedAddress];

      // FIX #3 — log only non-sensitive identifiers, and only in debug
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
  // FIX #4 — Token expiry validation
  // ─────────────────────────────────────────────────────────────

  /// Decodes the JWT payload and returns true if the token is expired or
  /// malformed. A 60-second buffer avoids using a token that expires mid-request.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64Url → base64 with padding
      String payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);

      final decoded = utf8.decode(base64Url.decode(payload));
      final map     = jsonDecode(decoded) as Map<String, dynamic>;
      final exp     = map['exp'];

      // No exp claim → treat as non-expiring (e.g. API keys)
      if (exp == null) return false;

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
  // FIX #12 — Required field validation
  // ─────────────────────────────────────────────────────────────

  void _assertRequiredUserFields(Map<String, dynamic> data) {
    // Backend might return 'id' or '_id'
    if (data['id'] == null && data['_id'] == null) {
      throw const FormatException('Auth response missing required field: id');
    }

    const required = ['name', 'email', 'role'];
    for (final field in required) {
      if (data[field] == null) {
        throw FormatException('Auth response missing required field: $field');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Error Helper
  // ─────────────────────────────────────────────────────────────

  String _translateAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found': return 'No user found for that email.';
        case 'wrong-password': return 'Wrong password provided.';
        case 'email-already-in-use': return 'An account already exists for that email.';
        case 'invalid-credential': return 'Invalid email or password.';
        case 'network-request-failed': return 'Network error. Please check your connection.';
      }
    }
    return error.toString().replaceAll('Exception: ', '').replaceAll('Exception', '');
  }

  // ─────────────────────────────────────────────────────────────
  // Login
  // ─────────────────────────────────────────────────────────────

  Future<void> login(BuildContext context, String email, String password) async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;
    _setLoading(true);

    try {
      final data = await locator<AuthRepository>().login(email, password);
      await _persistAuthResponse(data);
      _initializeAblySafely();
      _syncFCMTokenSafely();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] login error: $e');
      if (context.mounted) {
        UIUtils.showErrorDialog(context, 'Login Failed', _translateAuthError(e));
      }
    } finally {
      _authOperationInProgress = false;
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Register
  // ─────────────────────────────────────────────────────────────

  Future<void> register(BuildContext context, Map<String, dynamic> payload) async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;
    _setLoading(true);

    try {
      final data = await locator<AuthRepository>().register(payload);
      await _persistAuthResponse(data);
      _initializeAblySafely();
      _syncFCMTokenSafely();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] register error: $e');
      if (context.mounted) {
        UIUtils.showErrorDialog(context, 'Registration Failed', _translateAuthError(e));
      }
    } finally {
      _authOperationInProgress = false;
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FCM Token Sync
  // ─────────────────────────────────────────────────────────────

  /// Fire-and-forget wrapper with error handling.
  /// FIX #8 — unawaited calls must carry a catchError.
  void _syncFCMTokenSafely() {
    syncFCMToken().catchError((Object e) {
      if (kDebugMode) debugPrint('[AuthProvider] FCM sync failed (non-fatal): $e');
    });
  }

  Future<void> syncFCMToken() async {
    if (!isAuthenticated) return;

    // FIX #2 — FCM token is obtained and forwarded to the server only.
    // It is NEVER assigned to _token, which holds the backend JWT exclusively.
    final fcmToken = await notificationService.getToken();
    if (fcmToken == null) return;

    if (kDebugMode) debugPrint('[AuthProvider] Syncing FCM token with backend');

    await Future.wait([
      locator<AuthRepository>().updateProfile({'fcmToken': fcmToken}),
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
        final ok = response.statusCode == 200 &&
            response.data['success'] == true;
        debugPrint('[AuthProvider] FCM token save: ${ok ? 'OK' : 'failed'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] _pushFcmTokenToBackend error: $e');
      // Non-fatal — next app start will retry
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Persist auth response
  // ─────────────────────────────────────────────────────────────

  Future<void> _persistAuthResponse(Map<String, dynamic> data) async {
    final userData = data['user'] ?? data;

    if (userData is! Map) {
      throw const FormatException(
        'Invalid auth response: expected a user object',
      );
    }

    final userMap = Map<String, dynamic>.from(userData);

    // FIX #12 — validate before construction
    _assertRequiredUserFields(userMap);

    final user  = UserProfile.fromJson(userMap);
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw const FormatException('Invalid auth response: missing token');
    }

    _user  = user;
    _token = token; // Backend JWT — never an FCM token

    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kUser,  value: jsonEncode(user.toJson())),
    ]);

    // FIX #3 — no full token or email in logs
    if (kDebugMode) {
      debugPrint(
        '[AuthProvider] Auth persisted — '
        'User ID: ${user.id}, Role: ${user.role}',
      );
    }

    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // FIX #2 — Token refresh listener
  // The FCM token rotates independently of the backend JWT.
  // Refreshing the FCM token must NEVER touch _token (the JWT).
  // ─────────────────────────────────────────────────────────────

  void _setupTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) return;

    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      // A new FCM token is available — sync it with the backend.
      // Do NOT store it in _token or overwrite the JWT in secure storage.
      if (kDebugMode) debugPrint('[AuthProvider] FCM token rotated — re-syncing');
      _syncFCMTokenSafely();
    });

    _tokenRefreshListenerAttached = true;
  }

  // ─────────────────────────────────────────────────────────────
  // Ably
  // ─────────────────────────────────────────────────────────────

  /// Fire-and-forget wrapper with error handling.
  /// FIX #8 — unawaited calls must carry a catchError.
  void _initializeAblySafely() {
    _initializeAbly().catchError((Object e) {
      if (kDebugMode) debugPrint('[AuthProvider] Ably init failed (non-fatal): $e');
    });
  }

  Future<void> _initializeAbly() async {
    if (_ablyListenersAttached) return;

    final userId = _user?.id;
    if (userId == null) return;

    await _ablyService.initAbly(userId);
    _ablyService.addRoleListener(_handleRoleUpdate);
    _ablyService.addStoreApprovalListener(_handleStoreApproval);
    _ablyService.addWalletListener(refreshUser);

    // FIX #8 — fire-and-forget with catchError
    notificationService.subscribeToUserTopic(userId).catchError((Object e) {
      if (kDebugMode) debugPrint('[AuthProvider] FCM topic subscribe failed: $e');
    });

    _ablyListenersAttached = true;
  }

  // ─────────────────────────────────────────────────────────────
  // Locations
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchLocation() async {
    try {
      final locs = await locator<LocationRepository>().getLocations();
      _locations = locs;
      _safeNotify();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] fetchLocation error: $e');
    }
  }

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
      final data     = await locator<AuthRepository>().updateProfile(updates);
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
      final data     = await locator<AuthRepository>().getProfile();
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
      final data = await locator<AuthRepository>().toggleFavorite(storeId);
      if (data['success'] == true) {
        // FIX #13 — still a map-key update but with explicit cast to catch
        // backend shape changes at runtime rather than silently storing junk.
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

    final updates = <String, dynamic>{
      'name':  ?name,
      'phone': ?phone,
    };

    await updateUser(updates); // Optimistic

    try {
      await locator<AuthRepository>().updateProfile(updates);
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] updateNameAndPhone error: $e');
      // Non-fatal
    }
  }

  // Added hasSufficientFunds back to AuthProvider for compatibility.
  /// Returns true if the user's wallet balance is sufficient for the given total.
  bool hasSufficientFunds(double total) {
    return (user?.walletBalance ?? 0) >= total;
  }

  void setGuestInfo({String? name, String? phone}) {
    if (name  != null) _guestName  = name;
    if (phone != null) _guestPhone = phone;
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Social Sign-In
  // ─────────────────────────────────────────────────────────────

  Future<void> signInWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential   = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken  = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      final data = await locator<AuthRepository>().loginWithGoogle(firebaseIdToken);
      await _persistAuthResponse(data);
      _initializeAblySafely();
      _syncFCMTokenSafely();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] signInWithGoogle error: $e');
      if (context.mounted) {
        UIUtils.showErrorDialog(context, 'Google Sign-In Failed', _translateAuthError(e));
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    _setLoading(true);
    try {
      final rawNonce = _generateNonce();
      final nonce    = _sha256ofString(rawNonce);

      if (kDebugMode) {
        debugPrint('[AuthProvider] signInWithApple: rawNonce=$rawNonce, hashedNonce=$nonce');
      }

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

      if (kDebugMode) {
        debugPrint('[AuthProvider] Apple Credential received: email=${appleCredential.email}, '
            'identityToken length=${idToken.length}');
        try {
          final parts = idToken.split('.');
          if (parts.length > 1) {
            String payload = parts[1];
            while (payload.length % 4 != 0) {
              payload += '=';
            }
            final decoded = utf8.decode(base64Url.decode(payload));
            debugPrint('[AuthProvider] ID Token Payload: $decoded');
          }
        } catch (e) {
          debugPrint('[AuthProvider] Could not decode ID Token: $e');
        }
      }

      final credential = OAuthProvider('apple.com').credential(
        idToken:  idToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential  = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();

      if (kDebugMode) {
        debugPrint('[AuthProvider] Firebase Sign-In successful. ID Token length=${firebaseIdToken?.length}');
      }

      if (firebaseIdToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      String? fullName;
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        fullName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (fullName.isEmpty) fullName = null;
      }

      final data = await locator<AuthRepository>().loginWithApple(
        firebaseIdToken,
        name: fullName,
      );
      await _persistAuthResponse(data);
      _initializeAblySafely();
      _syncFCMTokenSafely();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[AuthProvider] signInWithApple error: $e');
        debugPrint('[AuthProvider] Stack trace: $stack');
      }
      if (context.mounted) {
        UIUtils.showErrorDialog(context, 'Apple Sign-In Failed', _translateAuthError(e));
      }
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
      await locator<AuthRepository>().deleteAccount();
      await logout();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] deleteAccount error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _reauthenticateIfNeeded(User user) async {
    final providers = user.providerData.map((p) => p.providerId).toList();

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
      final credential = OAuthProvider('apple.com').credential(
        idToken:  idToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      await user.reauthenticateWithCredential(credential);
    } else if (providers.contains('google.com')) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google re-authentication cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  String _generateNonce([int length = 32]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // ─────────────────────────────────────────────────────────────
  // Store application
  // ─────────────────────────────────────────────────────────────

  Future<void> applyForStore(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await locator<AuthRepository>().applyForStore(data);
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
    updateUser({'role': role});
  }

  void _handleStoreApproval(String storeId) {
    if (_disposed || _user == null || _user!.isStoreApproved) return;
    updateUser({'isStoreApproved': true});
  }

  // ─────────────────────────────────────────────────────────────
  // Unauthorized
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
        // FIX #8 — fire-and-forget with catchError
        notificationService.unsubscribeFromUserTopic(userId).catchError((Object e) {
          if (kDebugMode) debugPrint('[AuthProvider] FCM unsubscribe failed: $e');
        });
      }

      await _clearSession();

      _ablyService.disconnect();

      // FIX #10 — reset real-time flags so listeners re-attach on next login
      _ablyListenersAttached       = false;
      _tokenRefreshListenerAttached = false;

      if (disconnectGoogle) {
        await _googleSignIn.signOut();
      }
    } finally {
      _authOperationInProgress = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Clear Session
  // FIX #5 — targeted deletes instead of deleteAll() to avoid wiping
  //           keys owned by other modules in the same app.
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
  // Update User
  // ─────────────────────────────────────────────────────────────

  Future<void> updateUser(Map<String, dynamic> updates) async {
    final current = _user;
    if (current == null) return;

    final updated = UserProfile.fromJson({
      ...current.toJson(),
      ...updates,
    });

    _user = updated;
    await _storage.write(key: _kUser, value: jsonEncode(updated.toJson()));
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Loading
  // ─────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Safe notify
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
    // FIX #6 — use injected reference, not global
    _apiService.onUnauthorized = null;
    _ablyService.disconnect();
    super.dispose();
  }
}