import '../services/api_service.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiService.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await apiService.dio.post('/auth/register', data: userData);
    return response.data;
  }

  Future<Map<String, dynamic>> loginWithGoogle(String token) async {
    final response = await apiService.dio.post('/auth/google/oauth', data: {
      'token': token,
    });
    return response.data;
  }
}

final authRepository = AuthRepository();
