import 'dart:convert';

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
          debugPrint('✅ [API] ${response.statusCode} ${response.requestOptions.path}');
          if (response.data != null) {
            debugPrint('   Response: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('❌ [API] ${e.response?.statusCode ?? 'Network Error'} ${e.requestOptions.path}');
          
          String message = e.message ?? 'Unknown error';
          if (e.response?.data is Map) {
            message = e.response?.data['message'] ?? e.response?.data['error'] ?? message;
            debugPrint('   Error Body: ${e.response?.data}');
          } else if (e.response?.data is String && (e.response?.data as String).isNotEmpty) {
            message = e.response?.data;
          }
          
          debugPrint('   Message: $message');
          return handler.next(e);
        },
      ),
    );
  }
}

final apiService = ApiService();
