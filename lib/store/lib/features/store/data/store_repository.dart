import 'package:campuschow/store/lib/core/network/api_client.dart';
import 'package:campuschow/store/lib/features/dashboard/data/staff_member_model.dart';
import 'package:campuschow/store/lib/features/store/data/store_model.dart';

class StoreRepository {
  Future<List<Store>> getStores() async {
    final response = await apiService.dio.get('/stores');
    return (response.data as List)
        .map((s) => Store.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<Store?> getOwnerStore(String userId) async {
    try {
      // Let the backend filter — don't download the whole table
      final response = await apiService.dio.get('/stores', queryParameters: {'ownerId': userId});
      final stores = (response.data as List)
          .map((s) => Store.fromJson(s as Map<String, dynamic>))
          .toList();
      if (stores.isEmpty) return null;
      return stores.first;
    } catch (_) {
      return null;
    }
  }

  Future<Store> toggleStoreStatus(String storeId, bool isOpen) async {
    final response = await apiService.dio.patch(
      '/stores/$storeId/toggle',
      data: {'isOpen': isOpen},
    );
    return Store.fromJson(response.data);
  }

  Future<Store> updateStore(String storeId, Map<String, dynamic> data) async {
    final response = await apiService.dio.put('/stores/$storeId', data: data);
    return Store.fromJson(response.data);
  }

  Future<List<StaffMember>> getStaff(String storeId) async {
    final response = await apiService.dio.get('/stores/$storeId/staff');
    return (response.data as List).map((i) => StaffMember.fromJson(i)).toList();
  }

  Future<StaffMember> addStaff(String storeId, String email) async {
    final response = await apiService.dio.post(
      '/stores/$storeId/staff',
      data: {'email': email},
    );
    return StaffMember.fromJson(response.data);
  }

  Future<void> removeStaff(String storeId, String workerId) async {
    await apiService.dio.delete('/stores/$storeId/staff/$workerId');
  }
}

final storeRepository = StoreRepository();
