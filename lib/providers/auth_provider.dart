import 'dart:convert';
import '../locator.dart';
import '../services/ably_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/store.dart';
import '../repositories/auth_repository.dart';
import '../constants/static_data.dart';
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
  List<String> _locations = [];

  UserProfile? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get guestAddress => _guestAddress;
  String? get currentAddress => _user?.address ?? _guestAddress;
  List<String> get locations =>
      _locations.isEmpty ? StaticData.halls : _locations;

  Future<void> fetchLocations() async {
    debugPrint('[AuthProvider] fetchLocations');
    try {
      final res = await apiService.dio.get('/locations');
      debugPrint('[AuthProvider] fetchLocations response: $res');

      if (res.data != null && res.data is List) {
        _locations = List<String>.from(res.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] fetchLocations failed: $e');
      // Fallback to static data if API fails
      _locations = StaticData.halls;
      notifyListeners();
    }
  }

  bool get isAdmin => _user?.role == 'admin';
  bool get isStoreOwner => _user?.role == 'store_owner';
  bool get isRider => _user?.role == 'rider';
  bool get isAuthenticated => _token != null;
  Store? get adminStore => _adminStoreId != null
      ? StaticData.stores.firstWhere((s) => s.id == _adminStoreId)
      : null;

  /// Returns true if the user has enough money in their wallet to cover the [total].
  bool hasSufficientFunds(double total) {
    return (_user?.walletBalance ?? 0) >= total;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // By passing clientId directly, we prevent a native crash on iOS if GoogleService-Info.plist is missing.
    clientId: Platform.isIOS
        ? '471745302305-n6okkh5s155equosej1tsiibbu0l09ua.apps.googleusercontent.com'
        : '471745302305-lj75e24f9iabb6c9e3hkguha505omn9q.apps.googleusercontent.com',
    // The serverClientId is required to get an idToken for some backend verification flows
    serverClientId:
        '471745302305-jgs69lte05ua7ibf89pnmt6c02gi31fl.apps.googleusercontent.com',
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
      if (userData is Map && userData['id'] != null) {
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
      if (uData is Map && uData['id'] != null) {
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
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID token returned from Google');
      }

      final data = await locator<AuthRepository>().loginWithGoogle(idToken);
      final uData = data['user'] ?? data;
      if (uData is Map && uData['id'] != null) {
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
      debugPrint('[AuthProvider] Google Sign-In error: $e');
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
      if (uData is Map && uData['id'] != null) {
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
            userData.containsKey('id') &&
            userData['id'] != null) {
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

  void setGuestAddress(String address) {
    _guestAddress = address;
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
