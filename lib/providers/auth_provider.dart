import 'dart:convert';
import 'dart:async';
import 'dart:math';
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
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          serverClientId: const String.fromEnvironment(
            'SERVER_CLIENT_ID',
            defaultValue: '471745302305-tts3kroutn6jofuvcldfckjk4j7et6l2.apps.googleusercontent.com',
          ),
        ) {

    apiService.onUnauthorized = _handleUnauthorized;
  }

  // ─────────────────────────────────────────────────────────────
  // Dependencies
  // ─────────────────────────────────────────────────────────────

  final FlutterSecureStorage _storage;
  final GoogleSignIn _googleSignIn;

  // ─────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────

  UserProfile? _user;

  String? _token;

  bool _isLoading = false;

  bool _initialized = false;

  bool _disposed = false;

  bool _authOperationInProgress = false;

  String? _adminStoreId;

  String? _guestAddress;
  String? _guestName;
  String? _guestPhone;

  String? _selectedAddress;

  List<String> _locations = [];

  // Prevent duplicate Ably listeners
  bool _ablyListenersAttached = false;
  // Prevent duplicate token refresh listener
  bool _tokenRefreshListenerAttached = false;

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────

  UserProfile? get user => _user;

  String? get token => _token;

  bool get isLoading => _isLoading;

  bool get initialized => _initialized;

  bool get isAuthenticated =>
      _token != null && _user != null;

  bool get isAdmin =>
      _user?.role.toUpperCase() == 'ADMIN';

  bool get isStoreOwner =>
      _user?.role.toUpperCase() == 'STORE_OWNER';

  bool get isWorker =>
      _user?.role.toUpperCase() == 'STORE_WORKER';

  bool get isRider =>
      _user?.role.toUpperCase() == 'RIDER';

  bool get isStoreApproved =>
      _user?.isStoreApproved ?? false;

  List<String> get locations => _locations;

  String? get adminStoreId => _adminStoreId;

  String? get currentAddress => _selectedAddress ?? _guestAddress;
  String? get selectedAddress => _selectedAddress;
  String? get guestAddress => _guestAddress;
  String? get guestName => _guestName;
  String? get guestPhone => _guestPhone;

  // ─────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {

    if (_initialized) return;

    _setLoading(true);

    try {

      await Future.wait([
        _restoreSession(),
        fetchLocation(),
      ]);

      if (isAuthenticated) {
        await _initializeAbly();
        _setupTokenRefreshListener(); // Added token refresh listener
        unawaited(syncFCMToken());
      }

    } catch (e, stack) {

      debugPrint('[AuthProvider] initialize error');
      debugPrint(e.toString());
      debugPrint(stack.toString());

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

      final token = values['launch-fast-token'];
      final userJson = values['launch-fast-user'];

      if (token == null || userJson == null) {

        await _clearSession();

        return;
      }

      final decoded =
          jsonDecode(userJson) as Map<String, dynamic>;

      final restoredUser =
          UserProfile.fromJson(decoded);

      _token = token;
      _user = restoredUser;

      _adminStoreId =
          values['launch-fast-admin'];

      _guestAddress =
          values['launch-fast-guest-address'];

      _guestName =
          values['launch-fast-guest-name'];

      _guestPhone =
          values['launch-fast-guest-phone'];

      _selectedAddress =
          values['launch-fast-selected-address'];

      debugPrint('''
[AuthProvider] Session restored:
  User ID: ${_user?.id}
  Name: ${_user?.name}
  Email: ${_user?.email}
  Role: ${_user?.role}
  Token: ${_token != null ? 'Present' : 'Missing'}
  Admin Store ID: $_adminStoreId
''');

    } catch (e) {

      debugPrint(
        '[AuthProvider] restore failed: $e',
      );

      await _clearSession();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Login
  // ─────────────────────────────────────────────────────────────

  Future<void> login(
    String email,
    String password,
  ) async {

    if (_authOperationInProgress) {
      return;
    }

    _authOperationInProgress = true;

    _setLoading(true);

    try {

      final data =
          await locator<AuthRepository>()
              .login(email, password);

      await _persistAuthResponse(data);

      unawaited(_initializeAbly());
      unawaited(syncFCMToken());

      } finally {

      _authOperationInProgress = false;

      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Register
  // ─────────────────────────────────────────────────────────────

  Future<void> register(
    Map<String, dynamic> payload,
  ) async {

    if (_authOperationInProgress) {
      return;
    }

    _authOperationInProgress = true;

    _setLoading(true);

    try {

      final data =
          await locator<AuthRepository>()
              .register(payload);

      await _persistAuthResponse(data);

      unawaited(_initializeAbly());
      unawaited(syncFCMToken());

      } finally {

      _authOperationInProgress = false;

      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Sync FCM Token
  // ─────────────────────────────────────────────────────────────

  Future<void> syncFCMToken() async {
  if (!isAuthenticated) return;

  try {
    final token = await notificationService.getToken();
    if (token != null) {
      debugPrint('[AuthProvider] Syncing FCM Token: $token');
      // Legacy profile update (kept for compatibility)
      await locator<AuthRepository>().updateProfile({
        'fcmToken': token,
        'deviceToken': token, // Some backends use deviceToken
      });
      // Push token to dedicated save‑token route
      await _pushFcmTokenToBackend(token);
    }
  } catch (e) {
    debugPrint('[AuthProvider] FCM Token sync failed: $e');
  }
}
Future<void> _pushFcmTokenToBackend(String token) async {
  final userId = _user?.id;
  if (userId == null) return;

  try {
    final response = await apiService.dio.post(
      '/users/save-token',
      data: {'userId': userId, 'fcmToken': token},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      debugPrint('[AuthProvider] FCM token saved on server');
    } else {
      debugPrint('[AuthProvider] ❗️Failed to save token: ${response.data['error'] ?? 'unknown error'}');
    }
  } catch (e) {
    debugPrint('[AuthProvider] ❗️Exception while saving token: $e');
  }
}
  // ─────────────────────────────────────────────────────────────
  // Persist auth
  // ─────────────────────────────────────────────────────────────

  Future<void> _persistAuthResponse(
    Map<String, dynamic> data,
  ) async {

    final userData =
        data['user'] ?? data;

    if (userData is! Map) {
      throw Exception('Invalid auth response');
    }

    final user =
        UserProfile.fromJson(
          Map<String, dynamic>.from(userData),
        );

    final token = data['token'];

    if (token == null) {
      throw Exception('Missing token');
    }

    // Atomic state assignment
    _user = user;
    _token = token;

    // Atomic storage write
    await Future.wait([
      _storage.write(
        key: 'launch-fast-token',
        value: token,
      ),

      _storage.write(
        key: 'launch-fast-user',
        value: jsonEncode(user.toJson()),
      ),
    ]);

    debugPrint('''
[AuthProvider] Auth persisted:
  User ID: ${user.id}
  Name: ${user.name}
  Role: ${user.role}
  Token: ${token != null ? 'Present' : 'Missing'}
''');

    _safeNotify();
  }

  void _setupTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) return;
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('[AuthProvider] FCM token refreshed: $newToken');
      // Update local token storage
      _token = newToken;
      await _storage.write(key: 'launch-fast-token', value: newToken);
      // Sync with backend (profile update and save‑token route)
      await syncFCMToken();
    });
    _tokenRefreshListenerAttached = true;
  }


  Future<void> _initializeAbly() async {

    if (_ablyListenersAttached) {
      return;
    }

    final userId = _user?.id;

    if (userId == null) {
      return;
    }

    await ablyService.initAbly(userId);

    ablyService.addRoleListener(_handleRoleUpdate);

    ablyService.addStoreApprovalListener(
      _handleStoreApproval,
    );

    ablyService.addWalletListener(refreshUser);

    // Subscribe to the personal FCM topic so push notifications are delivered.
    // The backend sends to topic 'user_{userId}' via Firebase Admin SDK.
    unawaited(notificationService.subscribeToUserTopic(userId));

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
      debugPrint('[AuthProvider] fetchLocation error: $e');
    }
  }

  /// Alias for [fetchLocation] to satisfy store-side widgets.
  Future<void> fetchLocations() => fetchLocation();

  Future<void> setDeliveryAddress(String address) async {
    _selectedAddress = address;
    await _storage.write(key: 'launch-fast-selected-address', value: address);
    _safeNotify();
  }

  Future<void> setGuestAddress(String address) async {
    _guestAddress = address;
    await _storage.write(key: 'launch-fast-guest-address', value: address);
    _safeNotify();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      final data = await locator<AuthRepository>().updateProfile(updates);
      final userData = data['user'] ?? data;
      _user = UserProfile.fromJson(Map<String, dynamic>.from(userData));
      await _storage.write(key: 'launch-fast-user', value: jsonEncode(_user!.toJson()));
      _safeNotify();
    } catch (e) {
      debugPrint('[AuthProvider] updateProfile error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    try {
      final data = await locator<AuthRepository>().getProfile();
      final userData = data['user'] ?? data;
      _user = UserProfile.fromJson(Map<String, dynamic>.from(userData));
      await _storage.write(key: 'launch-fast-user', value: jsonEncode(_user!.toJson()));
      _safeNotify();
    } catch (e) {
      debugPrint('[AuthProvider] refreshUser error: $e');
    }
  }

  Future<void> toggleFavorite(String storeId) async {
    if (!isAuthenticated) return;
    try {
      final data = await locator<AuthRepository>().toggleFavorite(storeId);
      if (data['success'] == true) {
        final favorites = List<String>.from(data['favoriteStores']);
        updateUser({
          'favoriteStores': favorites,
        });
      }
    } catch (e) {
      debugPrint('[AuthProvider] toggleFavorite error: $e');
      rethrow;
    }
  }

  void updateRole(String role) {
    _handleRoleUpdate(role);
  }

  /// Silently saves a corrected [name] and/or [phone] to the backend profile.
  /// Optimistically updates local state first so the UI reflects the change
  /// immediately without waiting for the network round-trip.
  Future<void> updateNameAndPhone({String? name, String? phone}) async {
    if (!isAuthenticated || _user == null) return;
    if (name == null && phone == null) return;

    // Optimistic local update
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    updateUser(updates);

    try {
      await locator<AuthRepository>().updateProfile(updates);
    } catch (e) {
      debugPrint('[AuthProvider] updateNameAndPhone error: $e');
      // Non-fatal — the order will still carry the confirmed values.
    }
  }

  bool hasSufficientFunds(double total) {
    return (_user?.walletBalance ?? 0) >= total;
  }

  void setGuestInfo({String? name, String? phone}) {
    if (name != null) _guestName = name;
    if (phone != null) _guestPhone = phone;
    _safeNotify();
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign into Firebase so we get a Firebase ID token
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user!.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Send the Firebase ID token — the backend verifies it with Firebase Admin SDK.
      final data = await locator<AuthRepository>().loginWithGoogle(firebaseIdToken);
      
      await _persistAuthResponse(data);
      unawaited(_initializeAbly());
      unawaited(syncFCMToken());
    } catch (e) {
      debugPrint('[AuthProvider] signInWithGoogle error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithApple() async {
    _setLoading(true);
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign into Firebase so we get a Firebase ID token
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user!.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Send the Firebase ID token — the backend verifies it with Firebase Admin SDK.
      final data = await locator<AuthRepository>().loginWithApple(firebaseIdToken);
      
      await _persistAuthResponse(data);
      unawaited(_initializeAbly());
      unawaited(syncFCMToken());
    } catch (e) {
      debugPrint('[AuthProvider] signInWithApple error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _setLoading(true);

    try {
      // Re-authenticate if it's a social account to be safe
      await _reauthenticateIfNeeded(user);
      
      // 1. Delete from backend (MongoDB + Firebase Auth on server)
      await locator<AuthRepository>().deleteAccount();
      
      // 2. Clear local session
      await logout();
    } catch (e) {
      debugPrint('[AuthProvider] deleteAccount error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _reauthenticateIfNeeded(User user) async {
    final providers = user.providerData.map((p) => p.providerId).toList();
    
    if (providers.contains('apple.com')) {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [],
        nonce: nonce,
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      await user.reauthenticateWithCredential(credential);
    } else if (providers.contains('google.com')) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google re-authentication cancelled');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  String _generateNonce([int length = 32]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }


  Future<void> applyForStore(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await locator<AuthRepository>().applyForStore(data);
      final userData = response['user'] ?? response;
      _user = UserProfile.fromJson(Map<String, dynamic>.from(userData));
      await _storage.write(key: 'launch-fast-user', value: jsonEncode(_user!.toJson()));
      _safeNotify();
    } catch (e) {
      debugPrint('[AuthProvider] applyForStore error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _handleRoleUpdate(String role) {

    if (_disposed || _user == null) {
      return;
    }

    if (_user!.role == role) {
      return;
    }

    updateUser({
      'role': role,
    });
  }

  void _handleStoreApproval(String storeId) {

    if (_disposed || _user == null) {
      return;
    }

    if (_user!.isStoreApproved) {
      return;
    }

    updateUser({
      'isStoreApproved': true,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Unauthorized
  // ─────────────────────────────────────────────────────────────

  Future<void> _handleUnauthorized() async {

    debugPrint('[AuthProvider] unauthorized');

    await logout(
      disconnectGoogle: false,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────────

  Future<void> logout({
    bool disconnectGoogle = true,
  }) async {

    if (_authOperationInProgress) {
      return;
    }

    _authOperationInProgress = true;

    try {

      // Unsubscribe from FCM topic before clearing the session so we still
      // have the userId available.
      final userId = _user?.id;
      if (userId != null) {
        unawaited(notificationService.unsubscribeFromUserTopic(userId));
      }

      await _clearSession();

      ablyService.disconnect();

      if (disconnectGoogle) {
        await _googleSignIn.signOut();
      }

    } finally {

      _authOperationInProgress = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Clear Session
  // ─────────────────────────────────────────────────────────────

  Future<void> _clearSession() async {

    _user = null;
    _token = null;

    _adminStoreId = null;

    await _storage.deleteAll();

    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Update User
  // ─────────────────────────────────────────────────────────────

  Future<void> updateUser(
    Map<String, dynamic> updates,
  ) async {

    final current = _user;

    if (current == null) {
      return;
    }

    final updated =
        UserProfile.fromJson({
          ...current.toJson(),
          ...updates,
        });

    _user = updated;

    await _storage.write(
      key: 'launch-fast-user',
      value: jsonEncode(updated.toJson()),
    );

    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Loading
  // ─────────────────────────────────────────────────────────────

  void _setLoading(bool value) {

    if (_isLoading == value) {
      return;
    }

    _isLoading = value;

    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Safe notify
  // ─────────────────────────────────────────────────────────────

  void _safeNotify() {

    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────────

  @override
  void dispose() {

    _disposed = true;

    apiService.onUnauthorized = null;

    ablyService.disconnect();

    super.dispose();
  }
}