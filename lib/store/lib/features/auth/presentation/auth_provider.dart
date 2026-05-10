import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/error/failures.dart';
import 'package:campuschow/store/lib/core/providers/base_provider.dart';
import '../data/auth_repository.dart';
import 'package:campuschow/store/lib/features/auth/data/user_profile.dart';
import '../data/auth_local_data_source.dart';
import '../data/auth_google_service.dart';
import '../../../core/services/ably_service.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends BaseProvider {
  final AuthRepository _repo = authRepository;
  final AuthLocalDataSource _local = AuthLocalDataSource();
  final AuthGoogleService _google = AuthGoogleService();
  
  UserProfile? _user;
  String? _token;
  List<String> _locations = [];

  AuthProvider() {
    // Register the 401 handler so any expired-token response triggers logout.
    // This catches the Ably authCallback 401 that was crashing the app.
    apiService.onUnauthorized = _handleUnauthorized;
    _loadAuth();
  }

  UserProfile? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isStoreOwner => _user?.role == 'store_owner' || _user?.role == 'STORE_OWNER';
  bool get isStoreApproved => _user?.isStoreApproved ?? false;

  Future<void> _loadAuth() async {
    debugPrint('--- [AuthProvider] _loadAuth ---');
    setLoading(true);
    _token = await _local.getToken();
    final json = await _local.getUserJson();
    debugPrint('[AuthProvider] Token: ${_token != null}');
    debugPrint('[AuthProvider] User JSON: ${json != null}');
    if (json != null) {
      try {
        _user = UserProfile.fromJson(jsonDecode(json));
        debugPrint('[AuthProvider] User loaded: ${_user?.id}');
        _setupAbly();
      } catch (e) {
        debugPrint('[AuthProvider] Error parsing user JSON: $e');
      }
    }
    setLoading(false);
  }

  Future<void> login(String email, String password) async {
    debugPrint('--- [AuthProvider] login for $email ---');
    setLoading(true);
    (await _repo.login(email, password)).fold(
      (data) async {
        debugPrint('[AuthProvider] Login success');
        _token = data['token'];
        _user = UserProfile.fromJson(data['user'] ?? data);
        await _local.saveAuthData(_token!, _user!);
        _setupAbly();
      },
      (failure) {
        debugPrint('[AuthProvider] Login failure: ${failure.message}');
        setFailure(failure);
      },
    );
    setLoading(false);
  }

  Future<void> register(Map<String, dynamic> userData) async {
    debugPrint('--- [AuthProvider] register ---');
    setLoading(true);
    (await _repo.register(userData)).fold(
      (data) async {
        debugPrint('[AuthProvider] Register success');
        _token = data['token'];
        _user = UserProfile.fromJson(data['user'] ?? data);
        await _local.saveAuthData(_token!, _user!);
        _setupAbly();
      },
      (failure) {
        debugPrint('[AuthProvider] Register failure: ${failure.message}');
        setFailure(failure);
      },
    );
    setLoading(false);
  }

  void _setupAbly() {
    if (_user == null) {
      debugPrint('[AuthProvider] _setupAbly: User is null, skipping');
      return;
    }
    debugPrint('[AuthProvider] Setting up Ably for ${_user!.id}');
    // Fire-and-forget but catch errors so they surface in logs rather than crashing.
    ablyService.initAbly(_user!.id).catchError((Object e) {
      debugPrint('[AuthProvider] Ably initAbly error: $e');
    });
    ablyService.addRoleListener((r) => updateUser({'role': r}));
    ablyService.addStoreApprovalListener((_) => updateUser({'isStoreApproved': true}));
  }

  /// Called by [apiService] whenever any request returns 401.
  /// Clears all local state and notifies listeners (UI navigates to login).
  void _handleUnauthorized() {
    debugPrint('[AuthProvider] 401 received — forcing logout');
    _user = null;
    _token = null;
    ablyService.disconnect();
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> updates) {
    if (_user == null) return;
    _user = UserProfile.fromJson({..._user!.toJson(), ...updates});
    _local.saveUser(_user!);
    notifyListeners();
  }

  String? _guestAddress;
  String? get currentAddress => _user?.address ?? _guestAddress;

  Future<void> setGuestAddress(String address) async {
    _guestAddress = address;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    setLoading(true);
    (await _repo.updateProfile(data)).fold(
      (updated) {
        _user = UserProfile.fromJson(updated);
        _local.saveUser(_user!);
        notifyListeners();
      },
      setFailure,
    );
    setLoading(false);
  }

  Future<void> signInWithGoogle() async {
    setLoading(true);
    try {
      final idToken = await _google.getIdToken();
      if (idToken == null) {
        setLoading(false);
        return;
      }
      (await _repo.loginWithGoogle(idToken)).fold(
        (data) async {
          _token = data['token'];
          _user = UserProfile.fromJson(data['user'] ?? data);
          await _local.saveAuthData(_token!, _user!);
          _setupAbly();
        },
        setFailure,
      );
    } catch (e) {
      setFailure(ServerFailure(e.toString()));
    }
    setLoading(false);
  }

  Future<void> applyForStore(Map<String, dynamic> data) async {
    setLoading(true);
    (await _repo.applyForStore(data)).fold(
      (res) => updateUser({'adminStore': res['storeId'] ?? res['id']}),
      setFailure,
    );
    setLoading(false);
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _local.clearAll();
    await _google.signOut();
    ablyService.disconnect();
    notifyListeners();
  }

  List<String> get locations => _locations;

  Future<void> fetchLocations() async {
    debugPrint('[AuthProvider] fetchLocations');
    (await _repo.fetchLocations()).fold(
      (data) {
        _locations = data;
        debugPrint('[AuthProvider] fetchLocations response: $_locations');
        notifyListeners();
      },
      setFailure,
    );
  }
}
