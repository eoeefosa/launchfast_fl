import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final ApiService _apiService = GetIt.instance<ApiService>();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await userCredential.user!.getIdToken();

    final response = await _apiService.dio.post('/auth/login', data: {
      'idToken': idToken,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final email = userData['email'];
    final password = userData['password'];

    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await userCredential.user!.getIdToken();

    final dataToSend = Map<String, dynamic>.from(userData);
    dataToSend.remove('password');
    dataToSend['idToken'] = idToken;

    final response = await _apiService.dio.post('/auth/register', data: dataToSend);
    return response.data;
  }

  Future<Map<String, dynamic>> loginWithGoogle(String token) async {
    final response = await _apiService.dio.post('/auth/google/oauth', data: {
      'token': token,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> loginWithApple(String token, {String? name}) async {
    final response = await _apiService.dio.post('/auth/apple/oauth', data: {
      'token': token,
      'name': name,
    });
    return response.data;
  }

  Future<void> deleteAccount() async {
    await _apiService.dio.delete('/users/me');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final response = await _apiService.dio.patch('/auth/profile', data: updates);
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiService.dio.get('/auth/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> applyForStore(Map<String, dynamic> data) async {
    final response = await _apiService.dio.post('/stores/apply', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> toggleFavorite(String storeId) async {
    final response = await _apiService.dio.post('/users/favorites/toggle', data: {
      'storeId': storeId,
    });
    return response.data;
  }
}
