import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/failures.dart';

/// Called when any API response returns 401 (token expired / invalid).
/// Wire this up in AuthProvider so the app navigates to login automatically.
typedef OnUnauthorizedCallback = void Function();

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  /// Set this callback after construction so a 401 from any endpoint
  /// triggers a logout + navigation to the login screen.
  OnUnauthorizedCallback? onUnauthorized;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://campus-chow-three.vercel.app/api',
  );

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Increased: Vercel edge cold starts can take 10–15s on first wake
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_loggingInterceptor());
  }

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'launch-fast-token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // 401 means the stored JWT is expired or invalid.
        // Clear storage and fire the logout callback so the UI can
        // redirect to login — otherwise the error propagates silently
        // and crashes the Ably authCallback.
        if (e.response?.statusCode == 401) {
          debugPrint(
            '🔐 [ApiClient] 401 on ${e.requestOptions.path} — clearing session',
          );
          await storage.deleteAll();
          onUnauthorized?.call();
        }
        return handler.next(e);
      },
    );
  }

  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('🚀 [API Request] ${options.method} ${options.uri}');
        debugPrint('   Headers: ${options.headers}');
        debugPrint('   Data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
          '✅ [API Response] ${response.statusCode} ${response.requestOptions.path}',
        );
        debugPrint('   Data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint(
          '❌ [API Error] ${e.response?.statusCode} ${e.requestOptions.path}',
        );
        debugPrint('   Error Data: ${e.response?.data}');
        debugPrint('   Error Message: ${e.message}');
        return handler.next(e);
      },
    );
  }

  Failure handleDioError(DioException e) {
    debugPrint('--- Handling Dio Error ---');
    debugPrint('Error Type: ${e.type}');
    debugPrint('Response Data: ${e.response?.data}');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure('Connection timed out');
    }
    if (e.response?.statusCode == 401) {
      return const AuthFailure('Session expired. Please login again.');
    }
    final message =
        e.response?.data?['error'] ??
        e.response?.data?['message'] ??
        'An unexpected error occurred';
    debugPrint('Failure Message: $message');
    return ServerFailure(message);
  }
}

final apiService = ApiClient();
