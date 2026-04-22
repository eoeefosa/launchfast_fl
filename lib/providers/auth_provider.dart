import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/store.dart';
import '../repositories/auth_repository.dart';
import '../constants/static_data.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

class AuthProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();

  UserProfile? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAdmin = false;
  String? _adminStoreId;

  UserProfile? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _token != null;
  Store? get adminStore => _adminStoreId != null
      ? StaticData.stores.firstWhere((s) => s.id == _adminStoreId)
      : null;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // By passing clientId directly, we prevent a native crash on iOS if GoogleService-Info.plist is missing.
    clientId: Platform.isIOS
        ? '471745302305-ja90tj0aatmq2e7i6rjei1v08bpb2nvp.apps.googleusercontent.com'
        : '471745302305-lj75e24f9iabb6c9e3hkguha505omn9q.apps.googleusercontent.com',
    // The serverClientId is required to get an idToken for some backend verification flows
    serverClientId:
        '471745302305-tts3kroutn6jofuvcldfckjk4j7et6l2.apps.googleusercontent.com',
  );

  AuthProvider() {
    _loadAuth();
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
        _isAdmin = true;
        _adminStoreId = adminId;
      }
    } catch (e) {
      // print('Failed to load auth data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await authRepository.login(email, password);
      _user = UserProfile.fromJson(data['user']);
      _token = data['token'];

      await storage.write(key: 'launch-fast-token', value: _token);
      await storage.write(
        key: 'launch-fast-user',
        value: jsonEncode(_user!.toJson()),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await authRepository.register(userData);
      _user = UserProfile.fromJson(data['user']);
      _token = data['token'];

      await storage.write(key: 'launch-fast-token', value: _token);
      await storage.write(
        key: 'launch-fast-user',
        value: jsonEncode(_user!.toJson()),
      );
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

      final data = await authRepository.loginWithGoogle(idToken);
      _user = UserProfile.fromJson(data['user']);
      _token = data['token'];

      await storage.write(key: 'launch-fast-token', value: _token);
      await storage.write(
        key: 'launch-fast-user',
        value: jsonEncode(_user!.toJson()),
      );
    } catch (e) {
      // print('Google Sign-In Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool loginAdmin(String username, String password) {
    try {
      final store = StaticData.stores.firstWhere(
        (s) => s.adminUsername == username && s.adminPassword == password,
      );
      _isAdmin = true;
      _adminStoreId = store.id;
      storage.write(key: 'launch-fast-admin', value: store.id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _isAdmin = false;
    _adminStoreId = null;
    await storage.deleteAll();
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // print('Google sign out error: $e');
    }
    notifyListeners();
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

  void topUpWallet(double amount) {
    if (_user != null) {
      updateUser({'walletBalance': _user!.walletBalance + amount});
    }
  }
}
