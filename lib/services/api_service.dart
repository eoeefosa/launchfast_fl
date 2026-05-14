import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Called when any API response returns HTTP 401 (token expired / invalid).
/// Wire this up in AuthProvider so the app navigates to login automatically.
typedef OnUnauthorizedCallback = void Function();

class ApiService {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  /// Set this in AuthProvider after construction. Any 401 response will
  /// fire this callback so the session can be cleared and the user redirected.
  OnUnauthorizedCallback? onUnauthorized;

  // static const String baseUrl = 'https://campus-chow-three.vercel.app/api';

  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS Simulator.
  // If testing on a real device, replace this with your computer's local IP address.
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://campus-chow-three.vercel.app/api';
    }
    // Prefer local Next.js backend if available, otherwise fallback to Vercel.
    // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS Simulator.
    // For now, we'll keep the Vercel URL as default but provide the local option.
    return 'https://campus-chow-three.vercel.app/api';
    // return kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';
  }

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token;
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              token = await user.getIdToken();
            }
          } catch (e) {
            debugPrint('Error getting Firebase token: $e');
          }

          token ??= await storage.read(key: 'launch-fast-token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 🛠️ Generate Postman-ready cURL command
          final fullUrl = '${options.baseUrl}${options.path}';
          String curl = 'curl -X ${options.method.toUpperCase()} "$fullUrl"';

          options.headers.forEach((key, value) {
            curl += ' -H "$key: $value"';
          });

          if (options.data != null) {
            try {
              final payload = jsonEncode(options.data);
              curl += " -d '$payload'";
            } catch (e) {
              curl += " -d '${options.data.toString()}'";
            }
          }

          debugPrint('🚀 [POSTMAN/cURL]:\n$curl\n');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ [API] ${response.statusCode} ${response.requestOptions.path}',
          );
          if (response.data != null) {
            debugPrint('   Response: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint(
            '❌ [API] ${e.response?.statusCode ?? 'Network Error'} ${e.requestOptions.path}',
          );

          // 401 = token expired or invalid → force logout via the callback.
          if (e.response?.statusCode == 401) {
            debugPrint('🔐 [API] 401 detected — firing onUnauthorized callback');
            onUnauthorized?.call();
          }

          String message = e.message ?? 'Unknown error';
          if (e.response?.data is Map) {
            message =
                e.response?.data['message'] ??
                e.response?.data['error'] ??
                message;
            debugPrint('   Error Body: ${e.response?.data}');
          } else if (e.response?.data is String &&
              (e.response?.data as String).isNotEmpty) {
            message = e.response?.data;
          }

          debugPrint('   Message: $message');
          return handler.next(e);
        },
      ),
    );
  }

  static String getErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'No internet connection';
      }
      if (e.response?.data is Map) {
        return e.response?.data['message'] ??
            e.response?.data['error'] ??
            e.message ??
            'Unknown error';
      }
      if (e.response?.data is String &&
          (e.response?.data as String).isNotEmpty) {
        return e.response?.data as String;
      }
      return e.message ?? 'Unknown error';
    }
    return e.toString();
  }
}

final apiService = ApiService();
