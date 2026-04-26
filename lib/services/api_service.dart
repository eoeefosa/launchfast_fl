import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator
  static const String baseUrl = 'https://backend-lauchfast.vercel.app/api';

  // To test production, uncomment this instead:
  // static const String baseUrl = 'https://backend-lauchfast.vercel.app/api';

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'launch-fast-token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint(
            '🚀 [API] ${options.method.toUpperCase()} ${options.path}',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ [API] ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint(
            '❌ [API] ${e.response?.statusCode ?? 'Timeout'} ${e.requestOptions.path}',
          );
          debugPrint('Message: ${e.response?.data?['error'] ?? e.message}');
          return handler.next(e);
        },
      ),
    );
  }
}

final apiService = ApiService();
