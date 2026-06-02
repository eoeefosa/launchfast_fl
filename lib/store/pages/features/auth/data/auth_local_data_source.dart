import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'user_profile.dart';

class AuthLocalDataSource {
  final storage = const FlutterSecureStorage();
  static const _tokenKey = 'launch-fast-token';
  static const _userKey = 'launch-fast-user';
  static const _adminKey = 'launch-fast-admin';

  Future<String?> getToken() => storage.read(key: _tokenKey);
  Future<String?> getUserJson() => storage.read(key: _userKey);
  Future<String?> getAdminId() => storage.read(key: _adminKey);

  Future<void> saveAuthData(String token, UserProfile user) async {
    await storage.write(key: _tokenKey, value: token);
    await storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> saveUser(UserProfile user) async {
    await storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clearAll() => storage.deleteAll();
}
