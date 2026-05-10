import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:campuschow/repositories/location_repository.dart';

import '../locator.dart';
import '../services/ably_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/store.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

class AuthProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();

  UserProfile? _user;
  String? _token;
  bool _isLoading = false;
  String? _adminStoreId;
  String? _guestAddress;
  String? _guestName;
  String? _guestPhone;
  List<String> _locations = [];

  UserProfile? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get guestAddress => _guestAddress;
  String? get guestName => _guestName;
  String? get guestPhone => _guestPhone;
  String? get currentAddress =>
      _selectedAddress ?? _user?.address ?? _guestAddress;
  List<String> get locations => _locations;

  // Tracks the actively selected delivery address (always up-to-date in UI)
  String? _selectedAddress;

  Future<void> fetchLocations() async {
    try {
      _locations = await locator<LocationRepository>().getLocations();
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] fetchLocations failed: $e');
      notifyListeners();
    }
  }

  bool get isAdmin => _user?.role == 'admin' || _user?.role == 'ADMIN';
  bool get isStoreOwner => _user?.role == 'store_owner' || _user?.role == 'STORE_OWNER';
  bool get isRider => _user?.role == 'rider' || _user?.role == 'RIDER';
  bool get isAuthenticated => _token != null;
  Store? getAdminStore(List<Store> stores) => _adminStoreId != null
      ? stores.firstWhere((s) => s.id == _adminStoreId)
      : null;

  /// Returns true if the user has enough money in their wallet to cover the [total].
  bool hasSufficientFunds(double total) {
    if (_user == null) return false;
    return (_user?.walletBalance ?? 0) >= total;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // On Android, the clientId is automatically picked up from google-services.json.
    // Providing it manually here can often cause 'DEVELOPER_ERROR' (ApiException 10).
    clientId: Platform.isIOS
        ? '471745302305-n6okkh5s155equosej1tsiibbu0l09ua.apps.googleusercontent.com'
        : null,
    // The serverClientId is required to get an idToken for backend verification.
    // This MUST be the Web Client ID from your Firebase Console.
    serverClientId:
        '471745302305-tts3kroutn6jofuvcldfckjk4j7et6l2.apps.googleusercontent.com',
    // '471745302305-jgs69lte05ua7ibf89pnmt6c02gi31fl.apps.googleusercontent.com',
  );

  AuthProvider() {
    _loadAuth();
    fetchLocations();
  }

  /// Initializes the Ably real-time connection for the authenticated user.
  /// This is the ONLY place initAbly should be called from.
  void _initializeAbly() {
    final userId = _user?.id;
    if (userId != null) {
      locator<AblyService>().initAbly(userId);
    }
  }

  Future<void> _loadAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      _token = await storage.read(key: 'launch-fast-token');
      final userStr = await storage.read(key: 'launch-fast-user');
      final adminId = await storage.read(key: 'launch-fast-admin');
      _guestName = await storage.read(key: 'launch-fast-guest-name');
      _guestPhone = await storage.read(key: 'launch-fast-guest-phone');
      _guestAddress = await storage.read(key: 'launch-fast-guest-address');
      _selectedAddress = await storage.read(
        key: 'launch-fast-selected-address',
      );

      if (userStr != null) {
        _user = UserProfile.fromJson(jsonDecode(userStr));
      }
      if (adminId != null) {
        _adminStoreId = adminId;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Failed to load auth data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      _initializeAbly();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await locator<AuthRepository>().login(email, password);
      final userData = data['user'] ?? data;
      if (userData is Map && (userData['id'] != null || userData['_id'] != null)) {
        _user = UserProfile.fromJson(userData as Map<String, dynamic>);
        _token = data['token'];

        await storage.write(key: 'launch-fast-token', value: _token);
        await storage.write(
          key: 'launch-fast-user',
          value: jsonEncode(_user!.toJson()),
        );
        _initializeAbly();
      }
    } catch (e) {
      debugPrint('[AuthProvider] login failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await locator<AuthRepository>().register(userData);
      final uData = data['user'] ?? data;
      if (uData is Map && (uData['id'] != null || uData['_id'] != null)) {
        _user = UserProfile.fromJson(uData as Map<String, dynamic>);
        _token = data['token'];

        await storage.write(key: 'launch-fast-token', value: _token);
        await storage.write(
          key: 'launch-fast-user',
          value: jsonEncode(_user!.toJson()),
        );
        _initializeAbly();
      }
    } catch (e) {
      debugPrint('[AuthProvider] register failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    debugPrint('[AuthProvider] Starting Google Sign-In...');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint(
          '[AuthProvider] Google Sign-In was cancelled by user or failed silently.',
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('[AuthProvider] Google User: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      debugPrint('[AuthProvider] ID Token retrieved: ${idToken != null}');

      if (idToken == null) {
        throw Exception(
          'No ID token returned from Google. Ensure your SHA-1 is registered in Firebase Console.',
        );
      }

      debugPrint('[AuthProvider] Calling backend for Google login...');
      final data = await locator<AuthRepository>().loginWithGoogle(idToken);
      debugPrint('[AuthProvider] Backend response received: $data');

      final uData = data['user'] ?? data;
      if (uData is Map && (uData['id'] != null || uData['_id'] != null)) {
        _user = UserProfile.fromJson(uData as Map<String, dynamic>);
        _token = data['token'];

        await storage.write(key: 'launch-fast-token', value: _token);
        await storage.write(
          key: 'launch-fast-user',
          value: jsonEncode(_user!.toJson()),
        );
        _initializeAbly();
      }
    } on PlatformException catch (e) {
      String errorMessage;
      final code = e.code;
      final message = e.message;

      if (code == '10') {
        errorMessage =
            'DEVELOPER_ERROR (10): This usually means your SHA-1 fingerprint is missing or incorrect in the Google Cloud Console, or your package name does not match the registration.';
      } else if (code == '7') {
        errorMessage =
            'NETWORK_ERROR (7): Ensure your device has internet access and can reach the Google Play Services.';
      } else if (code == '12500') {
        errorMessage =
            'SIGN_IN_FAILED (12500): Check your Google Cloud Console configuration and ensure the Web Client ID is correct.';
      } else {
        errorMessage = 'Google Sign-In Platform Error ($code): $message';
      }

      debugPrint('[AuthProvider] Google Sign-In error: $errorMessage');
      rethrow;
    } catch (e) {
      debugPrint('[AuthProvider] Unexpected error during Google Sign-In: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    locator<AblyService>().disconnect();
    _user = null;
    _token = null;
    _adminStoreId = null;
    await storage.deleteAll();
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[AuthProvider] Google sign-out error: $e');
    }
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();
    // Optimistic Update: Update local state immediately for better UX
    final oldUser = _user;
    if (_user != null) {
      final updatedJson = {..._user!.toJson(), ...updates};
      _user = UserProfile.fromJson(updatedJson);
      notifyListeners();
    }

    try {
      final data = await locator<AuthRepository>().updateProfile(updates);
      final uData = data['user'] ?? data;
      if (uData is Map && (uData['id'] != null || uData['_id'] != null)) {
        _user = UserProfile.fromJson(uData as Map<String, dynamic>);
        await storage.write(
          key: 'launch-fast-user',
          value: jsonEncode(_user!.toJson()),
        );
      }
    } catch (e) {
      // Revert on error
      _user = oldUser;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUser(Map<String, dynamic> updates) {
    if (_user != null) {
      final updatedJson = {..._user!.toJson(), ...updates};
      _user = UserProfile.fromJson(updatedJson);
      storage.write(
        key: 'launch-fast-user',
        value: jsonEncode(_user!.toJson()),
      );
      notifyListeners();
    }
  }

  /// Called by Ably role-update listener to instantly update the in-memory
  /// user role and persist it, triggering navigation re-evaluation.
  void updateRole(String newRole) {
    if (_user != null && _user!.role != newRole) {
      updateUser({'role': newRole});
    }
  }

  /// Fetches fresh user data from the backend and persists it.
  Future<void> refreshUser() async {
    if (_token == null) return;
    try {
      final res = await apiService.dio.get('/auth/me');
      if (res.data != null) {
        Map<String, dynamic>? userData;

        if (res.data is Map) {
          final dataMap = res.data as Map;
          if (dataMap.containsKey('user') && dataMap['user'] is Map) {
            userData = Map<String, dynamic>.from(dataMap['user']);
          } else {
            userData = Map<String, dynamic>.from(dataMap);
          }
        }

        if (userData != null &&
            (userData.containsKey('id') || userData.containsKey('_id')) &&
            (userData['id'] != null || userData['_id'] != null)) {
          _user = UserProfile.fromJson(userData);
          await storage.write(
            key: 'launch-fast-user',
            value: jsonEncode(_user!.toJson()),
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[AuthProvider] refreshUser failed: $e');
    }
  }

  /// Updates the delivery address for both guest and authenticated users.
  /// Immediately reflects in the UI — backend sync is async for logged-in users.
  Future<void> setDeliveryAddress(String address) async {
    _selectedAddress = address;
    // Persist as the selected address so it survives app restarts
    await storage.write(key: 'launch-fast-selected-address', value: address);
    notifyListeners();

    if (_user != null) {
      // Sync to backend async without blocking the UI update
      try {
        await locator<AuthRepository>().updateProfile({'address': address});
        // Update local user model so currentAddress stays consistent
        final updatedJson = {..._user!.toJson(), 'address': address};
        _user = UserProfile.fromJson(updatedJson);
        await storage.write(
          key: 'launch-fast-user',
          value: jsonEncode(_user!.toJson()),
        );
      } catch (e) {
        debugPrint('[AuthProvider] setDeliveryAddress backend sync failed: $e');
        // Keep the local selection even if backend fails
      }
      notifyListeners();
    } else {
      // Guest user — also save as guest address
      _guestAddress = address;
      await storage.write(key: 'launch-fast-guest-address', value: address);
      notifyListeners();
    }
  }

  void setGuestAddress(String address) {
    _guestAddress = address;
    _selectedAddress = address;
    storage.write(key: 'launch-fast-guest-address', value: address);
    storage.write(key: 'launch-fast-selected-address', value: address);
    notifyListeners();
  }

  void setGuestInfo({String? name, String? phone}) {
    if (name != null) {
      _guestName = name;
      storage.write(key: 'launch-fast-guest-name', value: name);
    }
    if (phone != null) {
      _guestPhone = phone;
      storage.write(key: 'launch-fast-guest-phone', value: phone);
    }
    notifyListeners();
  }

  void topUpWallet(double amount) {
    if (_user != null) {
      updateUser({'walletBalance': _user!.walletBalance + amount});
    }
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    if (_user == null) return;

    // Optimistic update
    final oldStatus = _user!.isOnline;
    updateUser({'isOnline': isOnline});

    try {
      await locator<AuthRepository>().updateProfile({'isOnline': isOnline});
    } catch (e) {
      // Revert if API fails
      updateUser({'isOnline': oldStatus});
      rethrow;
    }
  }
}
