import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await userCredential.user!.getIdToken();

    final response = await apiService.dio.post('/auth/login', data: {
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

    final response = await apiService.dio.post('/auth/register', data: dataToSend);
    return response.data;
  }

  Future<Map<String, dynamic>> loginWithGoogle(String token) async {
    final response = await apiService.dio.post('/auth/google/oauth', data: {
      'token': token,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final response = await apiService.dio.patch('/auth/profile', data: updates);
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await apiService.dio.get('/auth/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> applyForStore(Map<String, dynamic> data) async {
    final response = await apiService.dio.post('/stores/apply', data: data);
    return response.data;
  }
}
