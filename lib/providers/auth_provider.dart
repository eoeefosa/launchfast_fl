import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:campuschow/repositories/location_repository.dart';

import '../locator.dart';
import '../services/ably_service.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {

  AuthProvider({
    FlutterSecureStorage? storage,
    GoogleSignIn? googleSignIn,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _googleSignIn = googleSignIn ?? GoogleSignIn() {

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

      debugPrint(
        '[AuthProvider] session restored '
        'user=${_user?.id} '
        'role=${_user?.role}',
      );

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

      await _initializeAbly();

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

      await _initializeAbly();

    } finally {

      _authOperationInProgress = false;

      _setLoading(false);
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

    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────
  // Ably
  // ─────────────────────────────────────────────────────────────

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

  void updateRole(String role) {
    _handleRoleUpdate(role);
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
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user!.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get ID token from Firebase');
      }

      // Just pass the Firebase ID Token to the Google OAuth endpoint
      final data = await locator<AuthRepository>().loginWithGoogle(idToken);
      
      await _persistAuthResponse(data);
      await _initializeAbly();
    } catch (e) {
      debugPrint('[AuthProvider] signInWithGoogle error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
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