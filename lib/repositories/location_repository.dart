import '../services/api_service.dart';

class LocationRepository {
  Future<List<String>> getLocations() async {
    final response = await apiService.dio.get('/locations');
    if (response.data != null && response.data is List) {
      return List<String>.from(response.data);
    }
    return [];
  }
}
