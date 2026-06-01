import '../services/api_service.dart';

class PlatformRepository {
  Future<Map<String, dynamic>> getCashbackLeaderboard({String? date}) async {
    final response = await apiService.dio.get(
      '/platform/cashback-leaderboard',
      queryParameters: date != null ? {'date': date} : null,
    );
    return response.data as Map<String, dynamic>;
  }
}
