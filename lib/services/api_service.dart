import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  static const String baseUrl = 'https://backend-lauchfast.vercel.app/api';


  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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
            '❌ [API] ${e.response?.statusCode ?? 'Network Error'} ${e.requestOptions.path}',
          );
          
          String message = e.message ?? 'Unknown error';
          if (e.response?.data is Map) {
            message = e.response?.data['message'] ?? e.response?.data['error'] ?? message;
          } else if (e.response?.data is String && (e.response?.data as String).isNotEmpty) {
            message = e.response?.data;
          }
          
          debugPrint('Message: $message');
          return handler.next(e);
        },
      ),
    );
  }
}

final apiService = ApiService();
