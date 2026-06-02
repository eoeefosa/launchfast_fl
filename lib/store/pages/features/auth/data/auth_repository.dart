import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/error/result.dart';
import '../../../core/error/failures.dart';

class AuthRepository {
  Future<Result<Map<String, dynamic>>> login(String email, String password) async {
    try {
      final response = await apiService.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return Result.success(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> register(Map<String, dynamic> userData) async {
    try {
      final response = await apiService.dio.post('/auth/register', data: userData);
      return Result.success(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> loginWithGoogle(String token) async {
    try {
      final response = await apiService.dio.post('/auth/google/oauth', data: {'token': token});
      return Result.success(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await apiService.dio.patch('/auth/profile', data: updates);
      return Result.success(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> applyForStore(Map<String, dynamic> data) async {
    try {
      final response = await apiService.dio.post('/stores/apply', data: data);
      return Result.success(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<String>>> fetchLocations() async {
    try {
      final response = await apiService.dio.get('/locations');
      return Result.success(List<String>.from(response.data));
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final authRepository = AuthRepository();
