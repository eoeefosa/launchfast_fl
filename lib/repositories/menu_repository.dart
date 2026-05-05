import '../services/api_service.dart';
import '../models/menu_item.dart';
import '../models/store.dart';

class MenuRepository {
  Future<List<MenuItem>> getMenuItems() async {
    final response = await apiService.dio.get('/menu');
    final data = response.data;
    if (data is Map && data.containsKey('items')) {
      return (data['items'] as List).map((i) => MenuItem.fromJson(i)).toList();
    }
    return (data as List).map((i) => MenuItem.fromJson(i)).toList();
  }

  Future<MenuItem> updateMenuItem(String id, Map<String, dynamic> data) async {
    final response = await apiService.dio.put('/menu/$id', data: data);
    return MenuItem.fromJson(response.data);
  }

  Future<List<Store>> getStores() async {
    final response = await apiService.dio.get('/stores');
    final data = response.data;
    if (data is! List) return [];
    return data.map((i) => Store.fromJson(i)).toList();
  }

  Future<Store> createStore(Map<String, dynamic> data) async {
    final response = await apiService.dio.post('/stores', data: data);
    return Store.fromJson(response.data);
  }

  Future<MenuItem> createMenuItem(Map<String, dynamic> data) async {
    final response = await apiService.dio.post('/menu', data: data);
    return MenuItem.fromJson(response.data);
  }

  Future<void> deleteMenuItem(String id) async {
    await apiService.dio.delete('/menu/$id');
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await apiService.dio.get('/platform/settings');
    return response.data as Map<String, dynamic>;
  }
}
